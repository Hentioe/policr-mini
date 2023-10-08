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
  def match?(%{chat_member: nil} = _update, _context) do
    false
  end

  @impl true
  def match?(%{chat_member: %{chat: %{type: "channel"}}}, _context) do
    false
  end

  @impl true
  def match?(%{chat_member: %{new_chat_member: %{status: status}}}, _context)
      when status not in ["restricted", "member"] do
    false
  end

  @impl true
  def match?(
        %{chat_member: %{new_chat_member: %{is_member: is_member, status: status}}},
        _context
      )
      when status == "restricted" and is_member == false do
    false
  end

  @impl true
  def match?(%{chat_member: %{old_chat_member: %{status: status}}}, _context)
      when status in ["member", "creator", "administrator"] do
    false
  end

  @impl true
  def match?(
        %{chat_member: %{old_chat_member: %{is_member: is_member, status: status}}},
        _context
      )
      when status == "restricted" and is_member == true do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_update, _context), do: true

  @impl true
  def handle(_update, context) do
    {:ok, action(context, :user_joined)}
  end
end
