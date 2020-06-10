defmodule PolicrMini.Bot.UserJoinedHandler do
  use PolicrMini.Bot.Handler

  @impl true
  def match?(_message, %{takeovered: false} = state), do: {false, state}

  @impl true
  def match?(%{new_chat_member: nil} = _message, state), do: {false, state}

  # 跳过机器人
  @impl true
  def match?(%{new_chat_member: %{is_bot: true}} = _message, state), do: {false, state}

  @impl true
  def match?(message, state) do
    %{id: joined_user_id} = message.new_chat_member

    {joined_user_id != bot_id(), state}
  end

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, new_chat_member: new_chat_member} = message

    Nadia.send_message(chat_id, "欢迎新成员【#{fullname(new_chat_member)} 】的加入！")

    {:ok, state}
  end
end
