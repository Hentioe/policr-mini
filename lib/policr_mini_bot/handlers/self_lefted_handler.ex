defmodule PolicrMiniBot.SelfLeftedHandler do
  use PolicrMiniBot.Handler

  alias PolicrMini.ChatBusiness

  @impl true
  def match?(%{left_chat_member: nil} = _message, state), do: {false, state}

  @impl true
  def match?(%{left_chat_member: %{id: lefted_user_id}} = _message, state),
    do: {lefted_user_id == bot_id(), state}

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    # 取消接管
    case ChatBusiness.get(chat_id) do
      {:ok, chat} -> chat |> ChatBusiness.takeover_cancelled()
      _ -> nil
    end

    {:ok, %{state | done: true}}
  end
end
