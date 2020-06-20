defmodule PolicrMini.Bot.SyncCommander do
  use PolicrMini.Bot.Commander, :sync

  alias PolicrMini.{ChatBusiness, UserBusiness}
  alias PolicrMini.Schema.Permission

  # 非管理员发送指令直接删除
  @impl true
  def handle(
        %{message_id: message_id, chat: %{id: chat_id}} = message,
        %{from_admin: false} = state
      ) do
    async(fn -> Nadia.delete_message(chat_id, message_id) end)

    {message, state}
  end

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    # 同步群组和管理员信息，并自动设置接管状态
    with {:ok, chat} <- synchronize_chat(chat_id),
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

        %{
          type: type,
          title: title,
          username: username,
          description: description,
          permissions: chat_permissions
        } = chat

        params = %{
          type: type,
          title: title,
          small_photo_id: small_photo_id,
          big_photo_id: big_photo_id,
          username: username,
          description: description,
          tg_can_add_web_page_previews: chat_permissions[:can_add_web_page_previews],
          tg_can_change_info: chat_permissions[:can_change_info],
          tg_can_invite_users: chat_permissions[:can_invite_users],
          tg_can_pin_messages: chat_permissions[:can_pin_messages],
          tg_can_send_media_messages: chat_permissions[:can_send_media_messages],
          tg_can_send_messages: chat_permissions[:can_send_messages],
          tg_can_send_other_messages: chat_permissions[:can_send_other_messages],
          tg_can_send_polls: chat_permissions[:can_send_polls]
        }

        params =
          if init,
            do: params |> Map.put(:is_take_over, false),
            else: params

        case ChatBusiness.fetch(chat_id, params) do
          {:error,
           %Ecto.Changeset{errors: [is_take_over: {"can't be blank", [validation: :required]}]}} ->
            ChatBusiness.fetch(chat_id, params |> Map.put(:is_take_over, false))

          r ->
            r
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
          |> Enum.filter(fn member -> !member.user.is_bot end)

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
              tg_can_restrict_members: member.can_restrict_members,
              tg_can_promote_members: member.can_promote_members
            }
          end)

        chat |> ChatBusiness.reset_administrators(permissions)

      e ->
        e
    end
  end
end
