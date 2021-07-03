defmodule PolicrMiniBot.HandleSelfPermissionsChangePlug do
  @moduledoc """
  响应自身权限修改的插件。
  """

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.{Logger, Instances}
  alias PolicrMini.Instances.Chat
  alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

  @doc """
  根据更新消息中的 `my_chat_member` 字段，处理自身权限变化。

  ## 以下情况将不进入流程（按顺序匹配）：
  - 更新不包含 `my_chat_member` 数据。
  - 更新来自频道或私聊。
  - 状态中的 `action` 字段为 `:self_joined` 或 `:self_lefted`。备注：自身加入和管理员权限无关，自身离开有独立的模块处理权限。
  - 成员现在的状态是 `member` 或 `restricted`，并且之前的状态也是 `memeber`、`restricted`。备注：普通权限变化和管理员权限无关。
  - 成员现在的状态是 `left` 并且之前的状态是 `kicked` 或 `restricted`。备注：从封禁或例外列表中解封用户和管理员权限变化无关。
  - 成员现在的状态是 `restricted` 并且之前的状态是 `left` 或 `kicked`。备注：将不在群内的用户添加到例外或封禁列表中和管理员权限变化无关。
  - 成员现在的状态是 `kicked` 并且之前的状态是 `left` 或 `restricted`。备注：将不在群内的用户添加到封禁列表与管理员变化无关。
  """

  # !注意! 由于依赖状态中的 `action` 字段，此模块需要位于管道中的涉及填充状态相关字段、相关值的插件后面。
  # 当前此模块需要保证位于 `PolicrMiniBot.InitUserJoinedActionPlug` 和 `PolicrMiniBot.HandleSelfLeftedPlug` 两个模块的后面。

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
  def call(_update, %{action: action} = state) when action in [:self_joined, :self_lefted] do
    {:ignored, state}
  end

  @impl true
  def call(
        %{
          my_chat_member: %{
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
          my_chat_member: %{
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
          my_chat_member: %{
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
          my_chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        },
        state
      )
      when status_new == "restricted" and status_old in ["left", "kicked"] do
    {:ignored, state}
  end

  # 从管理员降级为普通成员。
  @impl true
  def call(
        %{
          my_chat_member:
            %{
              new_chat_member: %{status: status_new} = new_chat_member,
              old_chat_member: %{status: status_old}
            } = my_chat_member
        } = _update,
        state
      )
      when status_new in ["restricted", "member"] and status_old == "administrator" do
    %{chat: %{id: chat_id}} = my_chat_member

    Logger.debug("The bot has been demoted to a normal member (#{chat_id}).")

    if new_chat_member.can_send_messages == false do
      # 如果没有发送消息权限，将直接退群。
      Telegex.leave_chat(chat_id)
    else
      if taken_over?(chat_id) do
        text = """
        由于本机器人的管理权限被撤销，已自动取消对新成员验证的接管。

        <i>若想再次启用，将本机器人重新提升为管理员即可。如已确定不再需要本机器人，可通过按钮退出或将它移除。</i>
        """

        markup = make_leave_markup(chat_id)

        Telegex.send_message(chat_id, text, reply_markup: markup, parse_mode: "HTML")

        cancel_takevoder(chat_id)
      end
    end

    {:ok, state}
  end

  # 从普通成员提升为管理员。
  @impl true
  def call(
        %{
          my_chat_member:
            %{
              new_chat_member: %{status: status_new} = new_chat_member,
              old_chat_member: %{status: status_old}
            } = my_chat_member
        } = _update,
        state
      )
      when status_new == "administrator" and status_old in ["restricted", "member"] do
    %{chat: %{id: chat_id}} = my_chat_member

    Logger.debug("The bot has been promoted to administrator (#{chat_id}).")

    if new_chat_member.can_restrict_members == false ||
         new_chat_member.can_delete_messages == false do
      # 最少权限不完整。

      text = """
      本机器人已经成为管理员了，但缺乏必要权限，尚无法启用接管验证相关功能。

      请至少赋予以下权限：
      - 删除消息（Delete messages）
      - 封禁成员（Ban users）

      <i>权限修改后会自动提供启用功能的按钮，亦可随时进入后台页面操作。</i>
      """

      Telegex.send_message(chat_id, text, parse_mode: "HTML")
    else
      text = """
      <b>本机器人已经具备相关管理权限了，是否需要接管新成员验证？</b>

      <i>群管理员可直接通过按钮启用，亦可随时进入后台页面操作。</i>
      """

      markup = make_enable_markup(chat_id)

      Telegex.send_message(chat_id, text, reply_markup: markup, parse_mode: "HTML")
    end

    {:ok, state}
  end

  # 管理权限的更新。
  @impl true
  def call(
        %{
          my_chat_member:
            %{
              new_chat_member: %{status: status_new},
              old_chat_member: %{status: status_old}
            } = my_chat_member
        } = _update,
        state
      )
      when status_new == "administrator" and status_old == "administrator" do
    %{chat: %{id: chat_id}} = my_chat_member

    Logger.debug("The bot administrator rights have been changed (#{chat_id}).")

    case rights_change_action(my_chat_member) do
      :restore_rights ->
        # 重新启用必要的权限。

        text = """
        本机器人现在已经具备必要管理权限了，是否重新接管新成员验证？

        <i>群管理员可直接通过按钮启用，亦可随时进入后台页面操作。</i>
        """

        markup = make_enable_markup(chat_id)

        {:ok, _} = Telegex.send_message(chat_id, text, reply_markup: markup, parse_mode: "HTML")

      :missing_rights ->
        # 必要权限被关闭。
        if taken_over?(chat_id) do
          text = """
          由于必要权限被关闭，已自动取消对新成员验证的接管。

          若想重新启用，请至少赋予以下权限：
          - 删除消息（Delete messages）
          - 封禁成员（Ban users）

          <i>权限修改后会自动提供启用功能的按钮，亦可随时进入后台页面操作。</i>
          """

          Telegex.send_message(chat_id, text, parse_mode: "HTML")

          cancel_takevoder(chat_id)
        end

      :ignore ->
        # 忽略无关的管理权限变化。
        nil
    end

    {:ok, state}
  end

  defp rights_change_action(%{
         new_chat_member: new_chat_member,
         old_chat_member: old_chat_member
       })
       when (old_chat_member.can_restrict_members == false or
               old_chat_member.can_delete_messages == false) and
              (new_chat_member.can_restrict_members == true and
                 new_chat_member.can_delete_messages == true) do
    :restore_rights
  end

  defp rights_change_action(%{
         new_chat_member: new_chat_member,
         old_chat_member: old_chat_member
       })
       when old_chat_member.can_restrict_members == true and
              old_chat_member.can_delete_messages == true and
              (new_chat_member.can_restrict_members == false or
                 new_chat_member.can_delete_messages == false) do
    :missing_rights
  end

  defp rights_change_action(_my_chat_member) do
    :ignore
  end

  defp cancel_takevoder(chat_id) do
    case Chat.get(chat_id) do
      {:ok, chat} -> Instances.cancel_chat_takeover(chat)
      _ -> nil
    end
  end

  @spec taken_over?(integer) :: boolean
  defp taken_over?(chat_id) do
    case Chat.get(chat_id) do
      {:ok, chat} -> chat.is_take_over
      _ -> false
    end
  end

  defp make_enable_markup(chat_id) do
    %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "启用新成员验证",
            callback_data: "enable:v1:#{chat_id}"
          }
        ]
      ]
    }
  end

  defp make_leave_markup(chat_id) do
    %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "请我离开本群",
            callback_data: "leave:v1:#{chat_id}"
          }
        ]
      ]
    }
  end
end
