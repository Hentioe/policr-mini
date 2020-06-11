defmodule PolicrMini.Bot.Helper do
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

  def at(user, parse_mode \\ "Markdown") when is_map(user) do
    case parse_mode do
      "Markdown" -> "[#{fullname(user)}](tg://user?id=#{user.id})"
    end
  end
end
