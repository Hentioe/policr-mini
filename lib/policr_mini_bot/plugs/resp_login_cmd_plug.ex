defmodule PolicrMiniBot.RespLoginCmdPlug do
  @moduledoc """
  登录命令。
  """

  use PolicrMiniBot, plug: [commander: :login]

  alias PolicrMini.PermissionBusiness
  alias PolicrMiniBot.Worker

  require Logger

  @doc """
  处理登录命令。

  此命令会提示用户私聊使用，也仅限于私聊使用。
  """
  def handle(%{chat: %{type: "private"}} = message, state) do
    %{chat: %{id: chat_id}, from: %{id: user_id}} = message

    with {:ok, :isadmin} <- check_user(user_id),
         {:ok, token} <- PolicrMiniWeb.create_token(user_id) do
      text = t("login.success", %{token: token})
      reply_markup = make_markup(user_id, token)

      case send_message(chat_id, text, reply_markup: reply_markup, parse_mode: "MarkdownV2ToHTML") do
        {:ok, _} ->
          {:ok, state}

        {:error, reason} ->
          Logger.error("Command response failed: #{inspect(command: "/login", reason: reason)}")

          {:error, state}
      end
    else
      {:error, :nonadmin} ->
        send_message(chat_id, t("login.non_admin"), parse_mode: "MarkdownV2ToHTML")

        {:ok, state}

      {:error, :notfound} ->
        send_message(chat_id, t("login.not_found"), parse_mode: "MarkdownV2ToHTML")

        {:ok, state}
    end
  end

  def handle(message, state) do
    %{chat: %{id: chat_id}, message_id: message_id} = message
    text = t("login.only_private")

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
            text: t("login.revoke_text"),
            callback_data: "revoke:v1:#{user_id}"
          }
        ],
        [
          %InlineKeyboardButton{
            text: t("login.join_text"),
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
