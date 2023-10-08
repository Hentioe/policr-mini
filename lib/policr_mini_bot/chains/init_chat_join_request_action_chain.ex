defmodule PolicrMiniBot.InitChatJoinRequestActionChain do
  @moduledoc """
  初始化上下文中的可能动作：`chat_join_request`。

  ## 注意
    - 此模块功能依赖对 `chat_join_request` 更新的接收。
  """

  use PolicrMiniBot.Chain

  @impl true
  def match?(%{chat_join_request: nil} = _update, _context) do
    false
  end

  @impl true
  def match?(%{chat_join_request: %{chat: %{type: "channel"}}}, _context) do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_update, _context), do: true

  @impl true
  def handle(_update, context) do
    {:ok, action(context, :chat_join_request)}
  end
end
