defmodule PolicrMiniBot.HandleJoinRequestChain do
  @moduledoc """
  处理加入请求。
  """

  use PolicrMiniBot.Chain

  import PolicrMiniBot.VerificationHelper

  require Logger

  # 忽略未接管。
  @impl true
  def match?(_update, %{taken_over: false} = _context) do
    false
  end

  # 忽略加入请求为空。
  @impl true
  def match?(%{chat_join_request: nil} = _update, _context) do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_update, _context), do: true

  @impl true
  def handle(update, context) do
    %{from: user, chat: chat, date: date} = update.chat_join_request

    # 私聊验证请求加入的用户
    embarrass_user(:join_request, chat.id, user, date)

    {:ok, context}
  end
end
