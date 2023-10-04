defmodule PolicrMiniBot.HandleMemberRemovedChain do
  @moduledoc """
  处理成员被移除。

  ## 以下情况皆不匹配
    - 字段 `left_chat_member` 的值为空。
    - 消息的发送者是机器人自己。
    - 已离开的成员是机器人自己。
  """

  use PolicrMiniBot.Chain, :message

  alias PolicrMiniBot.Worker

  require Logger

  # 忽略 `left_chat_member` 为空。
  @impl true
  def match?(%{left_chat_member: nil} = _message, _context), do: false

  # 忽略离开成员为机器人自己。
  @impl true
  def match?(
        %{left_chat_member: %{id: left_member_id}} = _message,
        %{bot: %{id: bot_id}} = _context
      )
      when left_member_id == bot_id do
    false
  end

  # 忽略消息发送来源为机器人自己。
  @impl true
  def match?(%{from: %{id: from_id}} = _message, %{bot: %{id: bot_id}} = _context)
      when from_id == bot_id do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_message, _context), do: true

  @impl true
  def handle(%{chat: chat} = message, context) do
    # TODO: 添加被移除用户的 ID 到日志消息中。
    Logger.debug("Member removed", chat_id: chat.id)

    Worker.async_delete_message(message.chat.id, message.message_id)

    {:ok, context}
  end
end
