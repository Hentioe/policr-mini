defmodule PolicrMiniBot.InitChatJoinRequestActionPlug do
  @moduledoc false

  use PolicrMiniBot, plug: :preheater

  # !注意! 此模块功能依赖对 `chat_join_request` 更新的接收。

  @impl true
  def call(%{chat_join_request: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_join_request: %{chat: %{type: "channel"}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(_update, state) do
    {:ok, action(state, :chat_join_request)}
  end
end
