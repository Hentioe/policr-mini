defmodule PolicrMiniBot.RespLoginCmdPlug do
  @moduledoc """
  登录命令。
  """

  use PolicrMiniBot, plug: [commander: :login]

  alias PolicrMini.PermissionBusiness
  alias PolicrMiniBot.Worker

  require Logger

  @sync_comment_text commands_text(
                       "如果您确定自己是群管理员，且群组中的确使用了本机器人。请通知群主或其它管理员在群内使用 %{command} 命令同步最新数据。",
                       command: "`/sync`"
                     )
  @doc """
  处理登录命令。

  此命令会提示用户私聊使用，也仅限于私聊使用。
  """
  def handle(%{chat: %{type: "private"}} = message, state) do
    %{chat: %{id: chat_id}, from: %{id: user_id}} = message

    with {:ok, :isadmin} <- check_user(user_id),
         {:ok, token} <- PolicrMiniWeb.create_token(user_id) do
      theader = commands_text("已为您创建一枚令牌，点击下方按钮可直接进入后台。亦或复制令牌手动登入。")

      tfooter =
        commands_text("有效期为 %{duration} %{unit}，过期需重新申请和登入。如怀疑泄漏请立即吊销。",
          duration: "1",
          unit: gettext("天")
        )

      tcomment = commands_text("安全小贴士：不可将按钮中的链接或登录令牌分享于他人，除非您想将控制权短暂的共享于他。")

      text = """
      #{theader}

      <code>#{token}</code>

      #{tfooter}

      <i>#{tcomment}</i>
      """

      reply_markup = make_markup(user_id, token)

      case send_message(chat_id, text, reply_markup: reply_markup, parse_mode: "HTML") do
        {:ok, _} ->
          {:ok, state}

        {:error, reason} ->
          Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")

          {:error, state}
      end
    else
      {:error, :nonadmin} ->
        theader = commands_text("未找到和您相关的权限记录")

        tcomment = @sync_comment_text

        text = """
        <b>#{theader}</b>

        <i>#{tcomment}</i>
        """

        send_message(chat_id, text, parse_mode: "HTML")

        {:ok, state}

      {:error, :notfound} ->
        theader = commands_text("未找到和您相关的用户记录")

        tcomment = @sync_comment_text

        text = """
        <b>#{theader}</b>

        <i>#{tcomment}</i>
        """

        send_message(chat_id, text, parse_mode: "HTML")

        {:ok, state}
    end
  end

  def handle(message, state) do
    %{chat: %{id: chat_id}, message_id: message_id} = message
    text = commands_text("请在私聊中使用此命令。")

    case reply_message(chat_id, message_id, text) do
      {:ok, sended_message} ->
        Worker.async_delete_message(chat_id, sended_message.message_id, delay_secs: 8)

      {:error, reason} ->
        Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")
    end

    Worker.async_delete_message(chat_id, message_id)

    {:ok, %{state | deleted: true}}
  end

  @spec make_markup(integer, String.t()) :: InlineKeyboardMarkup.t()
  defp make_markup(user_id, token) do
    root_url = PolicrMiniWeb.root_url(has_end_slash: false)

    %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: commands_text("吊销全部令牌"),
            callback_data: "revoke:v1:#{user_id}"
          }
        ],
        [
          %InlineKeyboardButton{
            text: commands_text("进入后台"),
            url: "#{root_url}/admin?token=#{token}"
          }
        ]
      ]
    }
  end

  @spec check_user(integer()) :: {:ok, :isadmin} | {:error, :nonadmin}
  defp check_user(user_id) do
    list = PermissionBusiness.find_list(user_id: user_id)

    if length(list) > 0, do: {:ok, :isadmin}, else: {:error, :nonadmin}
  end
end
