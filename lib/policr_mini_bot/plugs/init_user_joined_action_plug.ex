defmodule PolicrMiniBot.InitUserJoinedActionPlug do
  @moduledoc """
  初始化状态中可能的动作：用户加入群组。
  """

  # TODO: 弃用此模块。由于 TG 上游的变动，加群已放弃对 `message` 的处理。因此 `telegex_plug` 库的预制的抽象模块已无法适应此需求，需改进库设计。

  # !注意! 此模块功能依赖对 `chat_member` 更新的接收。

  use PolicrMiniBot, plug: :preheater

  alias PolicrMiniBot.State

  @doc """
  根据更新消息中的 `chat_member` 字段，设置状态中的动作为 `user_joined`。

  ## 以下情况将不进入验证流程（按顺序匹配）：
  - 更新来自频道。
  - 成员现在的状态不是 `restricted` 或 `member` 二者之一。
  - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `false`。
  - 成员之前的状态如果是 `member`、`creator`、`administrator` 三者之一。
  - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `true`。
  """

  # !注意! 此模块并不会根据群组是否接管、新成员的用户类型以及新成员的权限等数据进行过滤，这些交由实现相关处理流程的模块来做。

  @impl true
  def call(%{chat_member: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{chat: %{type: "channel"}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{new_chat_member: %{status: status}}}, state)
      when status not in ["restricted", "member"] do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{new_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == false do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{old_chat_member: %{status: status}}}, state)
      when status in ["member", "creator", "administrator"] do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{old_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == true do
    {:ignored, state}
  end

  @impl true
  def call(_update, state) do
    state = State.set_action(state, :user_joined)

    {:ok, state}
  end
end
