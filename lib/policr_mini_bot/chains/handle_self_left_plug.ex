defmodule PolicrMiniBot.HandleSelfLeftChain do
  @moduledoc """
  处理自身离开。

  ## 以下情况将不进入流程（按顺序匹配）：
    - 更新来自频道或私聊。
    - 成员现在的状态不是 `restricted`、`left`、`kicked` 三者之一。
    - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `true`。
    - 成员之前的状态是 `left`、`kicked` 二者之一。
    - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `false`。

  ## 注意
    - 此模块功能依赖对 `my_chat_member` 更新的接收。
  """

  use PolicrMiniBot.Chain

  alias PolicrMini.Instances
  alias PolicrMini.Instances.Chat

  require Logger

  @impl true
  def handle(%{my_chat_member: nil} = _update, context) do
    {:ok, context}
  end

  @impl true
  def handle(%{my_chat_member: %{chat: %{type: chat_type}}}, context)
      when chat_type in ["channel", "private"] do
    {:ok, context}
  end

  @impl true
  def handle(%{my_chat_member: %{new_chat_member: %{status: status}}}, context)
      when status not in ["restricted", "left", "kicked"] do
    {:ok, context}
  end

  @impl true
  def handle(
        %{my_chat_member: %{new_chat_member: %{is_member: is_member, status: status}}},
        context
      )
      when status == "restricted" and is_member == true do
    {:ok, context}
  end

  @impl true
  def handle(%{my_chat_member: %{old_chat_member: %{status: status}}}, context)
      when status in ["left", "kicked"] do
    {:ok, context}
  end

  @impl true
  def handle(
        %{my_chat_member: %{old_chat_member: %{is_member: is_member, status: status}}},
        context
      )
      when status == "restricted" and is_member == false do
    {:ok, context}
  end

  @impl true
  def handle(%{my_chat_member: my_chat_member} = _update, context) do
    %{chat: %{id: chat_id}} = my_chat_member

    Logger.info("Bot (@#{context.bot.username}) left group", chat_id: chat_id)

    context = action(context, :self_lefted)

    case Chat.get(chat_id) do
      {:ok, chat} ->
        # 更新群组
        Instances.chat_left_and_takeover_cancel(chat)

        {:ok, done(context)}

      {:error, :not_found, _} ->
        # 群组是有可能不存在的，因为普通群没有被保存，直接忽略处理。
        Logger.info("The left group was not found", chat_id: chat_id)

        {:ok, context}
    end
  end
end
