defmodule PolicrMiniBot.SelfLeftedHandler do
  @moduledoc """
  机器人自己离开群组的处理器。
  """

  use PolicrMiniBot, plug: :handler

  alias PolicrMini.ChatBusiness

  @doc """
  匹配消息中离开群组的用户是否为机器人自己。
  """
  @impl true
  def match(%{left_chat_member: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(%{left_chat_member: %{id: lefted_user_id}} = _message, state) do
    if lefted_user_id == bot_id() do
      {:match, state}
    else
      {:nomatch, state}
    end
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
