defmodule PolicrMiniBot.HandleJoinedMessageChain do
  @moduledoc """
  处理加入消息。

  ## 以下情况皆不匹配
    - 群组未接管。
    - 字段 `new_chat_members` 的值为空。
  """

  use PolicrMiniBot.Chain, :message

  alias PolicrMini.Chats
  alias PolicrMiniBot.Worker

  require Logger

  @type user :: PolicrMiniBot.Helper.mention_user()

  # 忽略未接管。
  @impl true
  def match?(_message, %{taken_over: false} = _context), do: false

  # 忽略 `new_chat_members` 为空。
  @impl true
  def match?(%{new_chat_members: nil} = _message, _context), do: false

  # 其余皆匹配。
  @impl true
  def match?(_message, _context), do: true

  @impl true
  def handle(%{chat: chat} = message, context) do
    # TOD0: 将 scheme 的获取放在一个独立的 chain 中，通过上下文传递。
    case Chats.find_or_init_scheme(chat.id) do
      {:ok, scheme} ->
        service_message_cleanup = scheme.service_message_cleanup || default!(:smc) || []

        if Enum.member?(service_message_cleanup, :joined) do
          # 删除服务消息。
          Worker.async_delete_message(chat.id, message.message_id)
        end
    end

    {:ok, %{context | done: true, deleted: true}}
  end
end
