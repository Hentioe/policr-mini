defmodule PolicrMini.Bot.SelfJoinedHandler do
  use PolicrMini.Bot.Handler

  alias PolicrMini.Schema.Permission
  alias PolicrMini.{ChatBusiness, UserBusiness}

  @impl true
  def match?(message, state) do
    is_match =
      if new_chat_member = message.new_chat_member do
        %{id: joined_user_id} = new_chat_member
        joined_user_id == PolicrMini.Bot.id()
      else
        false
      end

    {is_match, state}
  end

  @impl true
  def handle(message, state) do
    chat = message.chat

    %{id: chat_id, type: type, title: title, username: username} = chat

    chat_params = %{
      type: type,
      title: title,
      username: username,
      is_take_over: false
    }

    chat_params =
      case Nadia.get_chat(chat_id) do
        {:ok, chat} ->
          if photo = chat.photo do
            chat_params
            |> Map.put(:small_photo_id, photo.small_file_id)
            |> Map.put(:big_photo_id, photo.big_file_id)
          else
            chat_params
          end

        {:error, _} ->
          chat_params
      end

    # 添加群组信息
    with {:ok, chat} = ChatBusiness.fetch(chat_id, chat_params),
         {:ok, administrators} <- Nadia.get_chat_administrators(chat_id) do
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

      {:ok, _} = chat |> ChatBusiness.reset_administrators(permissions)

      Nadia.send_message(chat_id, "已成功登记本群信息，所有管理员皆可登入后台。将机器人提升为管理员将会开始工作。")
    else
      {:error, _} ->
        Nadia.send_message(chat_id, "出现了一些问题，机器人没有获取到管理员信息，请联系作者。")
    end

    {:ok, %{state | done: true}}
  end
end
