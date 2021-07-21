defmodule PolicrMiniBot.HandleSelfJoinedPlug do
  @moduledoc """
  自身加入新群组的处理器。
  """

  # TODO: 弃用此模块。由于 TG 上游的变动，加群已放弃对 `message` 的处理。因此 `telegex_plug` 库的预制的抽象模块已无法适应此需求，需改进库设计。

  # !注意! 此模块功能依赖对 `my_chat_member` 更新的接收。

  use PolicrMiniBot, plug: :preheater
  alias PolicrMini.{Logger, SchemeBusiness}
  alias PolicrMiniBot.Helper.Syncing
  alias PolicrMiniBot.{RespSyncCmdPlug, State}

  @doc """
  根据更新消息中的 `my_chat_member` 字段，处理自身加入。

  ## 以下情况将不进入流程（按顺序匹配）：
  - 更新来自频道或私聊。
  - 成员现在的状态不是 `restricted` 或 `member` 二者之一。
  - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `false`。
  - 成员之前的状态如果是 `member`、`administrator` 二者之一。
  - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `true`。
  """

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
  def call(
        %{
          my_chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        } = _update,
        state
      )
      when status_new not in ["restricted", "member", "administrator"] or
             (status_new == "administrator" and status_old not in ["left", "kicked"]) do
    # 添加了针对成员新状态是 "administrator" 但是此前状态并非 "left" 或 "kicked" 的匹配，这表示机器人是通过添加群成员进来的，在进入的同时就具备了权限。
    # TODO：将此项匹配逻辑更新到头部注释中。

    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{new_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == false do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{old_chat_member: %{status: status}}}, state)
      when status in ["member", "creator", "administrator"] do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: %{old_chat_member: %{is_member: is_member, status: status}}}, state)
      when status == "restricted" and is_member == true do
    {:ignored, state}
  end

  @impl true
  def call(%{my_chat_member: my_chat_member} = _update, state) do
    %{chat: %{id: chat_id, type: chat_type}} = my_chat_member

    Logger.debug("The bot is invited to a group (#{chat_id}).")
    state = State.set_action(state, :self_joined)

    # 非超级群直接退出。
    if chat_type != "supergroup", do: exits(chat_type, chat_id), else: handle_it(chat_id)

    {:ok, %{state | done: true}}
  end

  # 退出普通群。
  defp exits("group", chat_id) do
    send_message(chat_id, t("errors.no_super_group"))

    Telegex.leave_chat(chat_id)
  end

  # 退出频道。附加：目前测试被邀请进频道时并不会产生消息。
  defp exits("channel", message) do
    chat_id = message.chat.id

    Telegex.leave_chat(chat_id)
  end

  @spec handle_it(integer | binary) :: no_return()
  defp handle_it(chat_id) do
    # 同步群组和管理员信息。
    # 注意，创建群组后需要继续创建方案。
    with {:ok, chat} <- RespSyncCmdPlug.synchronize_chat(chat_id, true),
         {:ok, chat} <- Syncing.sync_for_chat_permissions(chat),
         {:ok, _} <- SchemeBusiness.fetch(chat_id),
         :ok <- response(chat_id) do
      if Enum.empty?(chat.permissions) do
        # 如果找不到任何管理员，发送相应提示。
        text = """
        *出现了一些异常*

        由于未能发现一位群管理，这会导致无人可拥有此群的后台权限。一般来讲，看到此消息的原因有二：

        1\\. 群组内不存在任何用户类型的管理员，包括群主。
        2\\. 群组内的管理员全部保持了匿名。

        针对情况二，本机器人会将修改自身权限（把我提升或添加为管理员）的群成员自动添加到后台权限中，防止无人可操作机器人。

        _注意：此设计只是为了避免在所有管理员匿名的情况下无法启用本机器人功能，并非解决管理员匿名所致的权限问题的最终方案。_
        """

        Telegex.send_message(chat_id, text, parse_mode: "MarkdownV2")
      end
    else
      # 无发消息权限，直接退出
      {:error, %Telegex.Model.Error{description: "Bad Request: have no rights to send a message"}} ->
        Telegex.leave_chat(chat_id)

      e ->
        Logger.unitized_error("Bot was invited to process", e)

        send_message(chat_id, t("self_joined.error"))
    end
  end

  @spec response(integer()) :: :ok | {:error, Telegex.Model.errors()}
  @doc """
  发送响应消息。
  """
  def response(chat_id) when is_integer(chat_id) do
    text = t("self_joined.text", %{bot_username: bot_username()})

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: t("self_joined.markup_text.subscribe"),
            url: "https://t.me/policr_changelog"
          }
        ]
      ]
    }

    case send_message(chat_id, text, reply_markup: markup, parse_mode: "HTML") do
      {:ok, _} -> :ok
      e -> e
    end
  end
end
