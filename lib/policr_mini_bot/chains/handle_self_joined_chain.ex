defmodule PolicrMiniBot.HandleSelfJoinedChain do
  @moduledoc """
  处理自身加入。

  ## 以下情况将不进入流程（按顺序匹配）：
    - 更新来自频道或私聊。
    - 成员现在的状态不是 `restricted` 或 `member` 二者之一。
    - 成员现在的状态如果是 `restricted`，但 `is_member` 为 `false`。
    - 成员之前的状态如果是 `member`、`administrator` 二者之一。
    - 成员之前的状态如果是 `restricted`，但 `is_member` 为 `true`。

  ## 注意
    - 此模块功能依赖对 `my_chat_member` 更新的接收。
  """

  use PolicrMiniBot.Chain

  alias PolicrMini.Chats
  alias PolicrMiniBot.Helper.Syncing
  alias Telegex.Type.{InlineKeyboardMarkup, InlineKeyboardButton}

  import PolicrMiniBot.Common

  require Logger

  defdelegate synchronize_chat(chat_id, init), to: PolicrMiniBot.RespSyncChain

  @impl true
  def match?(%{my_chat_member: nil} = _update, _context) do
    false
  end

  @impl true
  def match?(%{my_chat_member: %{chat: %{type: chat_type}}}, _context)
      when chat_type in ["channel", "private"] do
    false
  end

  # 添加了针对成员新状态是 "administrator" 但是此前状态并非 "left" 或 "kicked" 的匹配，这表示机器人是通过添加群成员进来的，在进入的同时就具备了权限。
  # TODO：将此项匹配逻辑更新到头部注释中。
  @impl true
  def match?(
        %{
          my_chat_member: %{
            new_chat_member: %{status: status_new},
            old_chat_member: %{status: status_old}
          }
        } = _update,
        _context
      )
      when status_new not in ["restricted", "member", "administrator"] or
             (status_new == "administrator" and status_old not in ["left", "kicked"]) do
    false
  end

  @impl true
  def match?(
        %{my_chat_member: %{new_chat_member: %{is_member: is_member, status: status}}},
        _context
      )
      when status == "restricted" and is_member == false do
    false
  end

  @impl true
  def match?(%{my_chat_member: %{old_chat_member: %{status: status}}}, _context)
      when status in ["member", "creator", "administrator"] do
    false
  end

  @impl true
  def match?(
        %{my_chat_member: %{old_chat_member: %{is_member: is_member, status: status}}},
        _context
      )
      when status == "restricted" and is_member == true do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_update, _context), do: true

  @impl true
  def handle(%{my_chat_member: my_chat_member} = _update, context) do
    %{chat: %{id: chat_id, type: chat_type}} = my_chat_member

    Logger.info("Bot (@#{context.bot.username}) invited to a new group", chat_id: chat_id)

    context = action(context, :self_joined)

    if chat_type == "supergroup" do
      _handle(chat_id, context)
    else
      # 非超级群直接退出。
      exits(chat_type, chat_id)
    end

    {:ok, context}
  end

  @spec _handle(integer | binary, map) :: no_return()
  defp _handle(chat_id, context) do
    # 同步群组和管理员信息。
    # 注意，创建群组后需要继续创建方案。
    with {:ok, chat} <- synchronize_chat(chat_id, true),
         {:ok, chat} <- Syncing.sync_for_chat_permissions(chat),
         {:ok, _} <- Chats.find_or_init_scheme(chat_id),
         :ok <- response_success(chat_id, context) do
      if Enum.empty?(chat.permissions) do
        # 如果找不到任何管理员，发送相应提示。
        # TODO: 此处的文字需要国际化
        text = """
        *出现了一些异常*

        由于未能发现一位群管理，这会导致无人可拥有此群的后台权限。一般来讲，看到此消息的原因有二：

        1\\. 群组内不存在任何用户类型的管理员，包括群主。
        2\\. 群组内的管理员全部保持了匿名。

        针对情况二，本机器人会将修改自身权限（把我提升或添加为管理员）的群成员自动添加到后台权限中，防止无人可操作机器人。

        _注意：此设计只是为了避免在所有管理员匿名的情况下无法启用本机器人功能，并非解决管理员匿名所致的权限问题的最终方案。_
        """

        send_text(chat_id, text, parse_mode: "MarkdownV2", logging: true)
      end
    else
      # 无发消息权限，直接退出
      {:error, %Telegex.Error{description: "Bad Request: have no rights to send a message"}} ->
        Telegex.leave_chat(chat_id)

      {:error, reason} ->
        Logger.error("Invitation handling failed: #{inspect(reason: reason)}", chat_id: chat_id)

        send_text(chat_id, commands_text("出现了一些问题，群组登记失败。请联系开发者。"), logging: true)
    end
  end

  # 退出普通群。
  defp exits("group", chat_id) do
    {parse_mode, text} = non_super_group_message()

    send_text(chat_id, text, parse_mode: parse_mode, logging: true)

    Telegex.leave_chat(chat_id)
  end

  # 退出频道。附加：目前测试被邀请进频道时并不会产生消息。
  defp exits("channel", message) do
    chat_id = message.chat.id

    Telegex.leave_chat(chat_id)
  end

  # 发送响应消息。
  defp response_success(chat_id, context) when is_integer(chat_id) do
    ttitle = commands_text("欢迎使用")
    tdesc = commands_text("已成功登记本群信息，所有管理员皆可登入后台。")

    tsteps =
      commands_text("""
      功能启用流程：
      1. 将本机器人提升为管理员。
      2. 操作一完成后将自动提供的功能启用按钮，或进入后台操作。
      """)

    tcloses =
      commands_text("""
      功能关闭方法（标准流程）：
      - 进入后台操作。

      功能自动关闭（非标准流程）：
      - 将机器人的管理员身份撤销。
      - 将机器人的任一必要管理权限关闭。

      以下非正常操作会导致机器人自动退出：
      - 关闭机器人的发消息权限。
      """)

    tadmin =
      commands_text(
        """
        进入后台方法：
        - 私聊发送 %{command} 命令
        """,
        command: "<code>/login</code>"
      )

    tcomment1 = commands_text("注意：当前后台网页仅支持桌面浏览器访问，手机尚未兼容。")
    tcomment2 = commands_text("撤销机器人的管理员或必要管理权限并不会导致机器人退群，也是被认可的取消接管方式。但将机器人禁言是毫无意义的，机器人只能选择退出。")
    tcomment3 = commands_text("为了避免误解，附加一些有关用户自行测试的说明：当退群重进的用户身份是群主时是不会产生验证的，请使用小号或拜托其他人测试。")

    text = """
    <b>#{ttitle}</b>

    #{tdesc}

    #{tsteps}

    #{tcloses}

    #{tadmin}

    <i>#{tcomment1}</i>

    <i>#{tcomment2}</i>

    <i>#{tcomment3}</i>
    """

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: commands_text("📜 最近更新"),
            url: "https://blog.hentioe.dev/posts/policr-mini-updates-2025-07-30.html"
          },
          %InlineKeyboardButton{
            text: commands_text("🔔 订阅更新"),
            url: "https://t.me/policr_changelog"
          }
        ],
        [
          %InlineKeyboardButton{
            text: commands_text("设置为管理员"),
            url: "https://t.me/#{context.bot.username()}?startgroup=added"
          }
        ]
      ]
    }

    case send_text(chat_id, text, reply_markup: markup, parse_mode: "HTML") do
      {:ok, _} -> :ok
      e -> e
    end
  end
end
