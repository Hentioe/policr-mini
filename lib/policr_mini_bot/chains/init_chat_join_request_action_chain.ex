defmodule PolicrMiniBot.InitChatJoinRequestActionChain do
  @moduledoc """
  初始化上下文中的可能动作：`chat_join_request`。

  ## 注意
    - 此模块功能依赖对 `chat_join_request` 更新的接收。
  """

  use PolicrMiniBot.Chain

  @impl true
  def handle(%{chat_join_request: nil} = _update, context) do
    {:ok, context}
  end

  @impl true
  def handle(%{chat_join_request: %{chat: %{type: "channel"}}}, context) do
    {:ok, context}
  end

  @impl true
  def handle(_update, context) do
    {:ok, action(context, :chat_join_request)}
  end
end
