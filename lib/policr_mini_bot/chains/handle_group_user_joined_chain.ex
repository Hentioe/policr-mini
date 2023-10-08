defmodule PolicrMiniBot.HandleGroupUserJoinedChain do
  @moduledoc """
  处理用户已加入群组。

  根据更新消息中的 `chat_member` 字段，验证用户。

  ## 以下情况将不进入处理流程（按顺序匹配）：
  - 更新来自频道。
  - 群组未接管。
  - 状态中的动作不是 `:user_joined`。
  - 拉人或进群的是管理员。
  - 拉人或进群的是机器人。

  ## 注意
    - 此模块功能依赖对 `chat_member` 更新的接收。
    - 此模块在管道中需位于 `PolicrMiniBot.InitUserJoinedActionChain` 模块的后面。
  """

  use PolicrMiniBot.Chain

  alias PolicrMiniBot.JoinReuquestHosting

  import PolicrMiniBot.VerificationHelper

  require Logger

  # 忽略 `chat_member` 为空。
  @impl true
  def match?(%{chat_member: nil} = _update, _context) do
    false
  end

  # 忽略频道消息。
  @impl true
  def match?(%{chat_member: %{chat: %{type: "channel"}}}, _context) do
    false
  end

  # 忽略未接管。
  @impl true
  def match?(_update, %{taken_over: false} = _context) do
    false
  end

  # 忽略非用户加入动作。
  @impl true
  def match?(_update, %{action: action} = _context) when action != :user_joined do
    false
  end

  # 忽略来自管理员。
  @impl true
  def match?(_update, %{from_admin: true} = _context) do
    false
  end

  # 忽略机器人。
  @impl true
  def match?(%{chat_member: %{new_chat_member: %{user: %{is_bot: true}}}}, _context) do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_update, _context), do: true

  @impl true
  def handle(%{chat_member: chat_member} = _update, context) do
    %{chat: chat, new_chat_member: %{user: user}, date: date} = chat_member

    Logger.debug(
      "A new member has joined group: #{inspect(user_id: user.id)}",
      chat_id: chat.id
    )

    request = JoinReuquestHosting.get(chat.id, user.id)

    if request && request.status == :approved do
      # 当加入请求存在托管且状态为 `:approved` 时，删除托管内容，忽略验证用户。
      :ok = JoinReuquestHosting.delete(chat.id, user.id)

      false
    else
      embarrass_user(:joined, chat.id, user, date)

      {:ok, context}
    end
  end
end
