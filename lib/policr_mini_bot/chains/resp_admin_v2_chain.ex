defmodule PolicrMiniBot.RespAdminV2Chain do
  @moduledoc """
  `/admin_v2` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :admin_v2}

  alias PolicrMiniWeb.AdminV2.TokenAuth
  alias PolicrMini.Accounts
  alias PolicrMini.Schema.User
  alias Telegex.Type.{InlineKeyboardButton, InlineKeyboardMarkup}

  require Logger

  def handle(%{chat: %{type: "private"}} = message, context) do
    %{chat: %{id: chat_id}, from: %{id: user_id} = from} = message

    owner_id = PolicrMiniBot.config_get(:owner_id)

    with {:owner, true} <- {:owner, user_id == owner_id},
         {:ok, token} <- create_token(from) do
      max_hours = div(TokenAuth.max_age(), 3600)

      text = """
      <b>💻 后台管理</b>

      已为您创建一个临时登录链接，有效期 <code>#{max_hours}</code> 小时。点击「进入后台」按钮将打开浏览器访问后台，此链接在有效期内可多次访问。

      <i>🤫 <b>请勿将此链接分享于他人，除非您正在短暂的分享控制权。若怀疑泄漏，请立即吊销</b></i>
      <i>⚠️ 请注意：<u>当前的后台仅支持桌面浏览器</u>，请尽量使用电脑而不是手机浏览器访问。</i>
      """

      reply_markup = make_markup(token)

      case send_text(chat_id, text, reply_markup: reply_markup, parse_mode: "HTML") do
        {:ok, _} ->
          {:ok, context}

        {:error, reason} ->
          Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")

          {:stop, context}
      end
    else
      {:error, :not_found} ->
        text = "未找到和您相关的管理员记录。"

        send_text(chat_id, text, parse_mode: "HTML", logging: true)

        {:ok, context}
    end
  end

  def handle(message, context) do
    %{chat: %{id: chat_id}, message_id: message_id} = message
    text = commands_text("请在私聊中使用此命令。")

    case send_text(chat_id, text, reply_to_message_id: message_id) do
      {:ok, %{message_id: message_id}} ->
        async_delete_message_after(chat_id, message_id, 8)

      {:error, reason} ->
        Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")
    end

    async_delete_message(chat_id, message_id)

    {:ok, %{context | deleted: true}}
  end

  @spec make_markup(String.t()) :: InlineKeyboardMarkup.t()
  defp make_markup(token) do
    root_url = PolicrMiniWeb.root_url(has_end_slash: false)

    %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: commands_text("吊销全部令牌"),
            callback_data: "revoke:v2:admin"
          }
        ],
        [
          %InlineKeyboardButton{
            text: commands_text("进入后台"),
            url: "#{root_url}/admin/v2?auth=#{token}"
          }
        ]
      ]
    }
  end

  @spec create_token(Telegex.Type.User.t()) :: {:ok, String.t()} | {:error, :not_found}
  defp create_token(from) do
    load_user =
      case Accounts.get_user(from.id) do
        nil ->
          sync_user(from)

        user ->
          {:ok, user}
      end

    case load_user do
      {:ok, user} ->
        token =
          Phoenix.Token.sign(PolicrMiniWeb.Endpoint, TokenAuth.namespace(), %{
            user_id: user.id,
            token_ver: user.token_ver
          })

        {:ok, token}

      err ->
        err
    end
  end

  @spec sync_user(Telegex.Type.User.t()) :: {:ok, User.t()} | {:error, any()}
  defp sync_user(from) do
    params = %{
      id: from.id,
      token_ver: 0,
      first_name: from.first_name,
      last_name: from.last_name,
      username: from.username
    }

    with {:ok, user} <- Accounts.upsert_user(from.id, params),
         {:ok, user} <- PolicrMiniBot.Helper.sync_user_photo(user) do
      {:ok, user}
    else
      err -> err
    end
  end
end
