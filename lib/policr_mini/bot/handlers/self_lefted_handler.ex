defmodule PolicrMini.Bot.SelfLeftedHandler do
  use PolicrMini.Bot.Handler

  alias PolicrMini.ChatBusiness

  @impl true
  def match?(message, state) do
    is_match =
      if left_chat_member = message.left_chat_member do
        %{id: lefted_user_id} = left_chat_member
        lefted_user_id == PolicrMini.Bot.id()
      else
        false
      end

    {is_match, state}
  end

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
