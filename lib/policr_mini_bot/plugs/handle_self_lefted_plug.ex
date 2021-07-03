defmodule PolicrMiniBot.HandleSelfLeftedPlug do
  @moduledoc """
  机器人自己离开群组的处理器。
  """

  # TODO: 弃用此模块。由于 TG 上游的变动，加群已放弃对 `message` 的处理。因此 `telegex_plug` 库的预制的抽象模块已无法适应此需求，需改进库设计。

  # !注意! 此模块功能依赖对 `my_chat_member` 更新的接收。

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.Instances
  alias PolicrMini.Instances.Chat
  alias PolicrMini.Logger
  alias PolicrMiniBot.State

  @doc """
  根据更新消息中的 `my_chat_member` 字段，执行退出流程。

  ## 以下情况将不进入流程（按顺序匹配）：
  - 更新来自频道或私聊。
  - 成员现在的状态不是 `restricted`、`left`、`kicked` 三者之一。
  - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `true`。
  - 成员之前的状态是 `left`、`kicked` 二者之一。
  - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `false`。
  """

  @impl true
  def call(%{my_chat_member: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{chat: %{type: chat_type}}}, state)
      when chat_type in ["channel", "private"] do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{new_chat_member: %{status: status}}}, state)
      when status not in ["restricted", "left", "kicked"] do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{new_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == true do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{old_chat_member: %{status: status}}}, state)
      when status in ["left", "kicked"] do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{old_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == false do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: my_chat_member} = _update, state) do
    %{chat: %{id: chat_id}} = my_chat_member

    Logger.debug("The bot has left a group (#{chat_id}).")
    state = State.set_action(state, :self_lefted)

    # 取消接管
    case Chat.get(chat_id) do
      {:ok, chat} -> Instances.cancel_chat_takeover(chat)
      _ -> nil
    end

    {:ok, %{state | done: true}}
  end
end
