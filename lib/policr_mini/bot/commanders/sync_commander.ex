defmodule PolicrMini.Bot.SyncCommander do
  use PolicrMini.Bot.Commander

  alias PolicrMini.{ChatBusiness, UserBusiness}
  alias PolicrMini.Schema.Permission

  command(:sync)

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    # 同步群组和管理员信息，并自动设置接管状态
    with {:ok, chat} = synchronize_chat(chat_id),
         {:ok, _} <- synchronize_administrators(chat),
         # 获取自身权限
         {:ok, member} <- Nadia.get_chat_member(chat_id, PolicrMini.Bot.id()) do
      is_admin = member.status == "administrator"

      last_is_take_over = chat.is_take_over

      if is_admin do
        chat |> ChatBusiness.update(%{is_take_over: true})
      else
        chat |> ChatBusiness.takeover_cancelled()
      end

      message_text = "同步完成。已更新群组和管理员数据。"

      message_text =
        if is_admin do
          message_text <>
            "因为本机器人具备权限，" <>
            if last_is_take_over, do: "新成员验证已处于接管状态。", else: "已接管新成员验证。"
        else
          message_text <>
            "因为本机器人不是管理员，" <>
            if(last_is_take_over, do: "已取消对新成员验证的接管。", else: "没有接管新成员验证的能力。")
        end

      send_message(chat_id, message_text)
    else
      {:error, _} ->
        send_message(chat_id, "出现了一些问题，同步失败。请联系作者。")
    end

    {:ok, state}
  end

  def synchronize_chat(chat_id, init \\ false) when is_integer(chat_id) do
    case Nadia.get_chat(chat_id) do
      {:ok, chat} ->
        {small_photo_id, big_photo_id} =
          if photo = chat.photo, do: {photo.small_file_id, photo.big_file_id}, else: {nil, nil}

        %{type: type, title: title, username: username} = chat

        params = %{
          type: type,
          title: title,
          small_photo_id: small_photo_id,
          big_photo_id: big_photo_id,
          username: username
        }

        params =
          if init,
            do: params |> Map.put(:is_take_over, false),
            else: params

        case ChatBusiness.fetch(chat_id, params) do
          {:error,
           %Ecto.Changeset{errors: [is_take_over: {"can't be blank", [validation: :required]}]}} ->
            ChatBusiness.fetch(chat_id, params |> Map.put(:is_take_over, false))
        end

      e ->
        e
    end
  end

  def synchronize_administrators(chat = %PolicrMini.Schema.Chat{id: chat_id})
      when is_integer(chat_id) do
    case Nadia.get_chat_administrators(chat_id) do
      {:ok, administrators} ->
        # 过滤自身
        administrators =
          administrators
          |> Enum.filter(fn member -> member.user.id != PolicrMini.Bot.id() end)

        # 更新用户列表
        administrators
        |> Enum.each(fn member ->
          user = member.user

          {:ok, _} =
            UserBusiness.fetch(
              user.id,
              %{
                id: user.id,
                first_name: user[:first_name],
                last_name: user[:last_name],
                username: user[:username]
              }
            )
        end)

        # 更新管理员列表
        permissions =
          administrators
          |> Enum.map(fn member ->
            %Permission{
              user_id: member.user.id,
              tg_is_owner: member.status == "creator",
              tg_can_promote_members: false,
              tg_can_restrict_members: true
            }
          end)

        chat |> ChatBusiness.reset_administrators(permissions)

      e ->
        e
    end
  end
end
