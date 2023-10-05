defmodule PolicrMiniBot.InitUserJoinedActionChain do
  @moduledoc """
  初始化上下文中的可能动作：`user_joined`。

  解读消息中的 `chat_member` 字段，设置上下文的 `action` 字段为 `user_joined` 或忽略。

  ## 以下情况将不进入验证流程（按顺序匹配）：
    - 更新来自频道。
    - 成员现在的状态不是 `restricted` 或 `member` 二者之一。
    - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `false`。
    - 成员之前的状态如果是 `member`、`creator`、`administrator` 三者之一。
    - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `true`。

  ## 注意
    - 此模块功能依赖对 `chat_member` 更新的接收。
    - 此模块不会根据当前群组是否接管、新成员的用户类型以及新成员的权限等数据进行过滤，这些交由实现相关模块来做。
  """

  use PolicrMiniBot.Chain

  @impl true
  def handle(%{chat_member: nil} = _update, context) do
    {:ok, context}
  end

  @impl true
  def handle(%{chat_member: %{chat: %{type: "channel"}}}, context) do
    {:ok, context}
  end

  @impl true
  def handle(%{chat_member: %{new_chat_member: %{status: status}}}, context)
      when status not in ["restricted", "member"] do
    {:ok, context}
  end

  @impl true
  def handle(%{chat_member: %{new_chat_member: %{is_member: is_member, status: status}}}, context)
      when status == "restricted" and is_member == false do
    {:ok, context}
  end

  @impl true
  def handle(%{chat_member: %{old_chat_member: %{status: status}}}, context)
      when status in ["member", "creator", "administrator"] do
    {:ok, context}
  end

  @impl true
  def handle(%{chat_member: %{old_chat_member: %{is_member: is_member, status: status}}}, context)
      when status == "restricted" and is_member == true do
    {:ok, context}
  end

  @impl true
  def handle(_update, context) do
    context = action(context, :user_joined)

    {:ok, context}
  end
end
