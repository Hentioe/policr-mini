defmodule PolicrMiniBot.RespConsoleChain do
  @moduledoc """
  `/console` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :console}

  require Logger

  def handle(%{chat: %{type: "private"}} = message, context) do
    %{chat: %{id: chat_id}} = message

    text = """
    <b>🚧 请使用新版 Mini Apps 控制台</b>

    您发送的 <code>/console</code> 命令是旧的控制台入口，当前已被弃用。请从 Mini Apps 入口进入新版控制台。

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
  #     # 检查用户头像
  #     check_user_photo(user_id)

  #     text = """
  #     <b>#{commands_text("进入控制台")}</b>

  #     <i>#{commands_text("控制台是新的功能管理页面，具有更美观的界面、更强大的功能、同时兼容移动与桌面访问。控制台将在未来取代旧后台页面。")}</i>

  #     #{commands_text("控制台正在积极开发中，关注%{channel}获取后续更新通知。", channel: "<a href=\"https://t.me/policr_changelog\">#{commands_text("更新频道")}</a>")}
  #     """

  #     reply_markup = build_markup(token)

  #     case send_text(chat_id, text, reply_markup: reply_markup, parse_mode: "HTML") do
  #       {:ok, _} ->
  #         {:ok, context}

  #       {:error, reason} ->
  #         Logger.error("Command response failed: #{inspect(command: "/console", reason: reason)}")

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

  #       # 由于依赖 `@sync_comment_text` 此处只能以 HTML 发送
  #       send_text(chat_id, text, parse_mode: "HTML", logging: true)

  #       {:ok, context}

  #     {:error, :notfound} ->
  #       theader = commands_text("未找到和您相关的用户记录")

  #       tcomment = sync_comment_text()

  #       text = """
  #       <b>#{theader}</b>

  #       <i>#{tcomment}</i>
  #       """

  #       # 由于依赖 `@sync_comment_text` 此处只能以 HTML 发送
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
  #       Logger.error("Command response failed: #{inspect(command: "/console", reason: reason)}")
  #   end

  #   async_delete_message(chat_id, message_id)

  #   {:ok, %{context | deleted: true}}
  # end

  # @spec build_markup(String.t()) :: InlineKeyboardMarkup.t()
  # defp build_markup(token) do
  #   root_url = PolicrMiniWeb.root_url(has_end_slash: false)

  #   %InlineKeyboardMarkup{
  #     inline_keyboard: [
  #       [
  #         %InlineKeyboardButton{
  #           text: commands_text("进入控制台"),
  #           url: "#{root_url}/console?id_token=#{token}"
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

  # defp check_user_photo(user_id, force \\ false) do
  #   # 根据 id 查询出用户
  #   case User.get(user_id) do
  #     {:ok, user} ->
  #       _check_user_photo(user, force)

  #     {:error, :not_found, _} ->
  #       Logger.warning("User not found: #{inspect(user_id)}")

  #       {:error, :not_found}
  #   end
  # end

  # defp _check_user_photo(user, true) do
  #   with {:ok, %{photos: photos}} <- Telegex.get_user_profile_photos(user.id),
  #        {:ok, user} <- UserBusiness.update(user, %{photo: user_photo_id(photos)}) do
  #     {:ok, user}
  #   else
  #     e ->
  #       e
  #   end
  # end

  # defp _check_user_photo(%{photo_id: photo_id} = user, false) when photo_id == nil do
  #   _check_user_photo(user, true)
  # end

  # defp _check_user_photo(user, false) do
  #   {:ok, user}
  # end

  # @spec user_photo_id(list) :: String.t()

  # defp user_photo_id([]) do
  #   # 空图像
  #   "unset"
  # end

  # defp user_photo_id([first_photo_sizes | _]) do
  #   finder = fn size ->
  #     size.width == 320 and size.height == 320
  #   end

  #   if size = Enum.find(first_photo_sizes, finder) do
  #     size.file_id
  #   else
  #     # 没有 320x320 尺寸的图片
  #     "unset"
  #   end
  # end
end
