defmodule PolicrMiniBot.HandleAdminPermissionsChangeChain do
  @moduledoc """
  处理管理员权限变更。

  ## 以下情况将不进入流程（按顺序匹配）：
    - 更新不包含 `chat_member` 数据。
    - 更新来自频道。
    - 状态中的 `action` 字段为 `:user_joined` 或 `:user_lefted`。备注：用户加入和管理员权限无关，用户离开有独立的模块处理权限。
    - 成员的用户类型是机器人。
    - 成员现在的状态是 `member` 或 `restricted`，并且之前的状态也是 `memeber`、`restricted`。备注：普通权限变化和管理员权限无关。
    - 成员现在的状态是 `left` 并且之前的状态是 `kicked` 或 `restricted`。备注：从封禁或例外列表中解封用户和管理员权限变化无关。
    - 成员现在的状态是 `restricted` 并且之前的状态是 `left` 或 `kicked`。备注：将不在群内的用户添加到例外或封禁列表中和管理员权限变化无关。
    - 成员现在的状态是 `kicked` 并且之前的状态是 `left` 或 `restricted`。备注：将不在群内的用户添加到封禁列表与管理员变化无关。

  ## 注意
    - 此模块功能依赖对 `chat_member` 更新的接收。
    - 此模块在管道中需位于 `PolicrMiniBot.HandleGroupMemberLeftChain` 模块的后面。
  """

  use PolicrMiniBot.Chain

  alias PolicrMini.Instances.Chat
  alias PolicrMiniBot.Helper.Syncing

  require Logger

  @impl true
  def match?(%{chat_member: nil} = _update, _context) do
    false
  end

  @impl true
  def match?(%{chat_member: %{chat: %{type: "channel"}}}, _context) do
    false
  end

  @impl true
  def match?(_update, %{action: action} = _context) when action in [:user_joined, :user_lefted] do
    false
  end

  def match?(%{chat_member: %{new_chat_member: %{user: %{is_bot: true}}}} = _update, _context) do
    false
  end

  @impl true
  def match?(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        _context
      )
      when status_new in ["member", "restricted"] and status_old in ["member", "restricted"] do
    false
  end

  @impl true
  def match?(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        _context
      )
      when status_new == "left" and status_old in ["kicked", "restricted"] do
    false
  end

  @impl true
  def match?(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        _context
      )
      when status_new == "kicked" and status_old in ["left", "restricted"] do
    false
  end

  @impl true
  def match?(
        %{
          chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        _context
      )
      when status_new == "restricted" and status_old in ["left", "kicked"] do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_update, _context), do: true

  @impl true
  def handle(%{chat_member: chat_member}, context) do
    %{chat: %{id: chat_id}, new_chat_member: %{user: %{id: user_id} = user}} = chat_member

    Logger.debug(
      "An administrator permissions has changed: #{inspect(chat_id: chat_id, user_id: user_id)}"
    )

    # TODO: 优化管理员权限的自动同步过程。改为对单个用户权限的更新或删除，而非根据 API 调用结果同步所有数据。

    with {:ok, chat} <- Chat.get(chat_id),
         {:ok, _} <- Syncing.sync_for_chat_permissions(chat) do
      theader =
        commands_text("检测到群成员 %{mention} 的管理权限变化，已自动同步至控制台权限中。",
          mention: mention(user, anonymization: false, parse_mode: "HTML")
        )

      tfooter =
        commands_text("提示：由于此特性的加入，在管理员权限变化的场景下将不再需要手动调用 %{command} 命令。",
          command: "<code>/sync</code>"
        )

      text = """
      #{theader}


      #{tfooter}
      """

      case send_text(chat_id, text, parse_mode: "HTML") do
        {:ok, msg} ->
          async_delete_message_after(chat_id, msg.message_id, 4)

        {:error, reason} ->
          Logger.warning(
            "Send permission synchronization message failed: #{inspect(chat_id: chat_id, reason: reason)}"
          )
      end
    else
      {:error, reason} ->
        send_text(
          chat_id,
          commands_text("检测到用户 %{mention} 的管理权限变化，但由于某些原因同步到控制台权限失败了。",
            mention: mention(user, anonymization: false)
          ),
          parse_mode: "MarkdownV2",
          logging: true
        )

        Logger.error(
          "Auto sync of chat permissions failed: #{inspect(chat_id: chat_id, user_id: user_id, reason: reason)}"
        )

      {:error, :not_found, _} ->
        # TODO: 保存群聊数据，并执行同步

        Logger.error("Chat not found", chat_id: chat_id)
    end

    {:ok, context}
  end
end
