defmodule PolicrMiniBot.HandleAdminPermissionsChangePlug do
  @moduledoc """
  同步管理员权限修改的插件。
  """

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.{Logger, ChatBusiness}
  alias PolicrMiniBot.RespSyncCmdPlug

  @doc """
  根据更新消息中的 `chat_member` 字段，同步管理员权限变化。

  ## 以下情况将不进入流程（按顺序匹配）：
  - 更新不包含 `chat_member` 数据。
  - 更新来自频道。
  - 状态中的 `action` 字段为 `:user_joined` 或 `:user_lefted`。备注：用户加入和管理员权限无关，用户离开有独立的模块处理权限。
  - 成员的用户类型是机器人。
  - 成员现在的状态是 `member` 或 `restricted`，并且之前的状态也是 `memeber`、`restricted`。备注：普通权限变化和管理员权限无关。
  - 成员现在的状态是 `left` 并且之前的状态是 `kicked` 或 `restricted`。备注：从封禁或例外列表中解封用户和管理员权限变化无关。
  - 成员现在的状态是 `restricted` 并且之前的状态是 `left` 或 `kicked`。备注：将不在群内的用户添加到例外或封禁列表中和管理员权限变化无关。
  - 成员现在的状态是 `kicked` 并且之前的状态是 `left` 或 `restricted`。备注：将不在群内的用户添加到封禁列表与管理员变化无关。
  """

  # !注意! 由于依赖状态中的 `action` 字段，此模块需要位于管道中的涉及填充状态相关字段、相关值的插件后面。
  # 当前此模块需要保证位于 `PolicrMiniBot.InitUserJoinedActionPlug` 和 `PolicrMiniBot.HandleUserLeftedGroupPlug` 两个模块的后面。
  @impl true
  def call(%{chat_member: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{chat: %{type: "channel"}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{action: action} = state) when action in [:user_joined, :user_lefted] do
    {:ignored, state}
  end

  def call(%{chat_member: %{new_chat_member: %{user: %{is_bot: is_bot}}}} = _update, state)
      when is_bot == true do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new in ["member", "restricted"] and status_old in ["member", "restricted"] do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new == "left" and status_old in ["kicked", "restricted"] do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new == "kicked" and status_old in ["left", "restricted"] do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new == "restricted" and status_old in ["left", "kicked"] do
    {:ignored, state}
  end

  # 有 bug 待处理：未接管导致状态字段没有填充。
  @impl true
  def call(%{chat_member: chat_member}, state) do
    %{chat: %{id: chat_id}, new_chat_member: %{user: %{id: user_id} = user}} = chat_member

    Logger.debug(
      "The permissions of an administrator have changed. #{inspect(chat_id: chat_id, user_id: user_id)}"
    )

    # TODO: 优化管理员权限的自动同步过程。改为对单个用户权限的更新或删除，而非根据 API 调用结果同步所有数据。

    with {:ok, chat} <- ChatBusiness.get(chat_id),
         {:ok, _} <- RespSyncCmdPlug.synchronize_administrators(chat) do
      text = """
      检测到用户 #{mention(user, anonymization: false, parse_mode: "HTML")} 的管理权限变化，已自动同步至后台权限中。

      <i>提示：由于此特性的加入，在管理员权限变化的场景下将不再需要手动调用 <code>/sync</code> 命令。</i>
      """

      case send_message(chat_id, text, parse_mode: "HTML") do
        {:ok, msg} ->
          Cleaner.delete_message(chat_id, msg.message_id, delay_seconds: 4)

        e ->
          Logger.unitized_error("Sending of messages with synchronized permissions",
            chat_id: chat_id,
            returns: e
          )
      end
    else
      e ->
        send_message(
          chat_id,
          "检测到用户 #{mention(user, anonymization: false)} 的管理权限变化，但由于某些原因同步到后台权限失败了。"
        )

        Logger.unitized_error("Automatically sync administrator permissions",
          chat_id: chat_id,
          user_id: user_id,
          returns: e
        )
    end

    {:ok, state}
  end
end
