defmodule PolicrMini.Bot.Helper do
  alias PolicrMini.ChatBusiness

  defdelegate bot_id(), to: PolicrMini.Bot, as: :id
  defdelegate bot_username(), to: PolicrMini.Bot, as: :username

  def fullname(%{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"
  def fullname(%{first_name: first_name}), do: first_name
  def fullname(%{last_name: last_name}), do: last_name
  def fullname(%{id: id}), do: Integer.to_string(id)

  def send_message(chat_id, text, options \\ []) do
    options =
      options
      |> Keyword.put_new(:disable_notification, true)
      |> Keyword.put_new(:parse_mode, "Markdown")

    Nadia.send_message(chat_id, text, options)
  end

  def reply_message(chat_id, message_id, text, options \\ []) do
    options = options |> Keyword.merge(reply_to_message_id: message_id)
    send_message(chat_id, text, options)
  end

  @default_restrict_permissions %Nadia.Model.ChatPermissions{
    can_send_messages: false,
    can_send_media_messages: false,
    can_send_polls: false,
    can_send_other_messages: false,
    can_add_web_page_previews: false,
    can_change_info: false,
    can_invite_users: false,
    can_pin_messages: false
  }

  def restrict_chat_member(chat_id, user_id) do
    Nadia.restrict_chat_member(chat_id, user_id, @default_restrict_permissions)
  end

  def derestrict_chat_member(chat_id, user_id) do
    {:ok,
     %{
       tg_can_send_messages: can_send_messages,
       tg_can_send_media_messages: can_send_media_messages,
       tg_can_send_polls: can_send_polls,
       tg_can_send_other_messages: can_send_other_messages,
       tg_can_add_web_page_previews: can_add_web_page_previews,
       tg_can_change_info: can_change_info,
       tg_can_invite_users: can_invite_users,
       tg_can_pin_messages: can_pin_messages
     }} = ChatBusiness.get(chat_id)

    Nadia.restrict_chat_member(chat_id, user_id, %Nadia.Model.ChatPermissions{
      can_send_messages: can_send_messages,
      can_send_media_messages: can_send_media_messages,
      can_send_polls: can_send_polls,
      can_send_other_messages: can_send_other_messages,
      can_add_web_page_previews: can_add_web_page_previews,
      can_change_info: can_change_info,
      can_invite_users: can_invite_users,
      can_pin_messages: can_pin_messages
    })
  end

  def at(user, parse_mode \\ "Markdown") when is_map(user) do
    case parse_mode do
      "Markdown" -> "[#{fullname(user)}](tg://user?id=#{user.id})"
    end
  end
end
