defmodule PolicrMiniBot.HandleGroupMemberLeftPlug do
  @moduledoc """
  群成员离开的处理器。
  """

  # TODO: 弃用此模块。由于 TG 上游的变动，加群已放弃对 `message` 的处理。因此 `telegex_plug` 库的预制的抽象模块已无法适应此需求，需改进库设计。

  # !注意! 此模块功能依赖对 `chat_member` 更新的接收。

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.PermissionBusiness

  require Logger

  @doc """
  根据更新消息中的 `chat_member` 字段，清理离开数据。

  ## 以下情况将不进入清理流程（按顺序匹配）：
  - 更新来自频道。
  - 成员现在的状态不是 `restricted`、`left`、`kicked` 三者之一。
  - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `true`。
  - 成员之前的状态是 `left`、`kicked` 二者之一。
  - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `false`。
  - 离开的群成员用户类型是机器人。
  """

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
      when status not in ["restricted", "left", "kicked"] do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{new_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == true do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{old_chat_member: %{status: status}}}, state)
      when status in ["left", "kicked"] do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{old_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == false do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{new_chat_member: %{user: %{is_bot: true}}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: chat_member} = update, state) do
    %{chat: %{id: chat_id}, new_chat_member: %{user: %{id: left_user_id} = user}} = chat_member

    Logger.debug("A group member has left: #{inspect(chat_id: chat_id, user_id: left_user_id)}")

    if left_user_id == bot_id() do
      # 跳过机器人自身
      {:ignored, state}
    else
      # 删除离开消息（此调用委托给 `PolicrMiniBot.HandleGroupMemberLeftMessagePlug` 处理）
      {_, state} = delete_left_message(update.message, state)
      state = action(state, :user_lefted)

      # 判断是否为管理员退出
      perm = PermissionBusiness.find(chat_id, left_user_id)
      # 此处的管理员不包括群主
      is_admin = perm && !perm.tg_is_owner

      if is_admin do
        # 如果是管理员则删除权限记录
        PermissionBusiness.delete(chat_id, left_user_id)

        theader =
          commands_text("已将曾经的管理员 %{mention} 的后台权限移除。",
            mention: mention(user, anonymization: false)
          )

        tfooter =
          commands_text("提示：由于此特性的加入，在管理员已离开群组的场景下将不再需要手动调用 %{command} 命令。", command: "`/sync`")

        text = """
        #{theader}

        _#{tfooter}_
        """

        send_text(chat_id, text, parse_mode: "MarkdownV2", logging: true)
      end

      {:ok, %{state | done: true}}
    end
  end

  defdelegate delete_left_message(message, state),
    to: PolicrMiniBot.HandleGroupMemberLeftMessagePlug,
    as: :handle
end
