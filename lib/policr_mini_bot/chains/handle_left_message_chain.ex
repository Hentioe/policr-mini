defmodule PolicrMiniBot.HandleLeftMessageChain do
  @moduledoc """
  处理离开消息。
  """

  use PolicrMiniBot.Chain, :message

  alias PolicrMini.Chats

  require Logger

  # 忽略未接管的群。
  @impl true
  def match?(_message, %{taken_over: false} = _context) do
    false
  end

  # 忽略离开成员数据为空。
  @impl true
  def match?(%{left_chat_member: nil} = _message, _context) do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_message, _context), do: true

  @impl true
  def handle(%{chat: chat, message_id: message_id} = _message, context) do
    context = action(context, :delete_left_message)

    # TOD0: 将 scheme 的获取放在一个独立的 chain 中，通过上下文传递。
    # 检测并删除服务消息。
    scheme = Chats.find_or_init_scheme!(chat.id)
    enabled_cleanup = scheme.service_message_cleanup || default!(:cleanup) || []

    if Enum.member?(enabled_cleanup, :left) do
      Logger.debug(
        "Delete message that member has left: #{inspect(message_id: message_id)}",
        chat_id: chat.id
      )

      # 删除服务消息。
      async_delete_message(chat.id, message_id)

      {:ok, %{context | deleted: true}}
    else
      {:ok, context}
    end
  end

  @impl true
  def handle(_, context), do: {:ok, context}
end
