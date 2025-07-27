defmodule PolicrMiniBot.RespLoginChain do
  @moduledoc """
  `/login` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :login}

  require Logger

  def handle(%{chat: %{type: "private"}} = message, context) do
    %{chat: %{id: chat_id}} = message

    text = """
    <b>🚧 请使用新版 Mini Apps 控制台</b>

    您发送的 <code>/login</code> 命令是旧的综合性后台入口，当前已被弃用。请参考以下新的入口：

    ‧ 如果您是群管理，请从 Mini Apps 入口进入新版控制台。
    ‧ 如果您是机器人拥有者，请使用 /admin_v2 命令。

    <i>💯 新版控制台是专门为群管理设计的，提供了更好的用户体验和更完整的功能。与 Telegram 集成在一起。</i>

    <i>⚠️ 注意：新控制台暂时不支持 Mini Apps 以外的入口使用。</i>
    """

    Telegex.send_message(chat_id, text, parse_mode: "HTML")

    {:stop, context}
  end

  # defp sync_comment_text do
  #   commands_text(
  #     "如果您确定自己是群管理员，且群组中的确使用了本机器人。请通知群主或其它管理员在群内使用 %{command} 命令同步最新数据。",
  #     command: "<code>/sync</code>"
  #   )
  # end

  # def handle(%{chat: %{type: "private"}} = message, context) do
  #   %{chat: %{id: chat_id}, from: %{id: user_id}} = message

  #   with {:ok, :isadmin} <- check_user(user_id),
  #        {:ok, token} <- PolicrMiniWeb.create_token(user_id) do
  #     text = """
  #     <b>#{commands_text("进入后台")}</b>

  #     #{commands_text("已为您创建一枚令牌，点击下方按钮可直接进入后台。亦或复制令牌手动登入。")}

  #     <code>#{token}</code>

  #     #{commands_text("有效期为 %{day_count} 天，过期需重新申请和登入。如怀疑泄漏请立即吊销。",
  #     day_count: 1)}

  #     <i>#{commands_text("安全小贴士：不可将按钮中的链接或登录令牌分享于他人，除非您想将控制权短暂的共享于他。")}</i>

  #     <i>#{commands_text("使用 /console 命令，可体验全新的功能管理页面！")}</i>
  #     """

  #     reply_markup = make_markup(user_id, token)

  #     case send_text(chat_id, text, reply_markup: reply_markup, parse_mode: "HTML") do
  #       {:ok, _} ->
  #         {:ok, context}

  #       {:error, reason} ->
  #         Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")

  #         {:stop, context}
  #     end
  #   else
  #     {:error, :nonadmin} ->
  #       theader = commands_text("未找到和您相关的权限记录")

  #       tcomment = sync_comment_text()

  #       text = """
  #       <b>#{theader}</b>

  #       <i>#{tcomment}</i>
  #       """

  #       # 由于依赖 `sync_comment_text()` 此处只能以 HTML 发送
  #       send_text(chat_id, text, parse_mode: "HTML", logging: true)

  #       {:ok, context}

  #     {:error, :notfound} ->
  #       theader = commands_text("未找到和您相关的用户记录")

  #       tcomment = sync_comment_text()

  #       text = """
  #       <b>#{theader}</b>

  #       <i>#{tcomment}</i>
  #       """

  #       # 由于依赖 `sync_comment_text()` 此处只能以 HTML 发送
  #       send_text(chat_id, text, parse_mode: "HTML", logging: true)

  #       {:ok, context}
  #   end
  # end

  # def handle(message, context) do
  #   %{chat: %{id: chat_id}, message_id: message_id} = message
  #   text = commands_text("请在私聊中使用此命令。")

  #   case send_text(chat_id, text, reply_to_message_id: message_id) do
  #     {:ok, %{message_id: message_id}} ->
  #       async_delete_message_after(chat_id, message_id, 8)

  #     {:error, reason} ->
  #       Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")
  #   end

  #   async_delete_message(chat_id, message_id)

  #   {:ok, %{context | deleted: true}}
  # end

  # @spec make_markup(integer, String.t()) :: InlineKeyboardMarkup.t()
  # defp make_markup(user_id, token) do
  #   root_url = PolicrMiniWeb.root_url(has_end_slash: false)

  #   %InlineKeyboardMarkup{
  #     inline_keyboard: [
  #       [
  #         %InlineKeyboardButton{
  #           text: commands_text("吊销全部令牌"),
  #           callback_data: "revoke:v1:#{user_id}"
  #         }
  #       ],
  #       [
  #         %InlineKeyboardButton{
  #           text: commands_text("进入后台"),
  #           url: "#{root_url}/admin?token=#{token}"
  #         }
  #       ]
  #     ]
  #   }
  # end

  # @spec check_user(integer()) :: {:ok, :isadmin} | {:error, :nonadmin}
  # defp check_user(user_id) do
  #   list = PermissionBusiness.find_list(user_id: user_id)

  #   if length(list) > 0, do: {:ok, :isadmin}, else: {:error, :nonadmin}
  # end
end
