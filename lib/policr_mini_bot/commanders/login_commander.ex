defmodule PolicrMiniBot.LoginCommander do
  @moduledoc """
  登录命令。
  """

  use PolicrMiniBot, plug: [commander: :login]

  require Logger

  alias PolicrMini.PermissionBusiness

  @doc """
  处理登录命令。

  此命令会提示用户私聊使用，也仅限于私聊使用。
  """
  def handle(%{chat: %{type: "private"}} = message, state) do
    %{chat: %{id: chat_id}, from: %{id: user_id}} = message

    # 检查用户是否具备权限记录
    if is_admin(user_id) do
      token = PolicrMiniWeb.create_token(user_id)
      text = t("login.success", %{token: token})
      reply_markup = make_markup(token)

      case send_message(chat_id, text, reply_markup: reply_markup, parse_mode: "MarkdownV2ToHTML") do
        {:ok, _} ->
          {:ok, state}

        e ->
          Logger.error("Error in response to `/login` command. Details: #{inspect(e)}")

          {:error, state}
      end
    else
      send_message(chat_id, t("login.not_admin"))

      {:ok, state}
    end
  end

  def handle(message, state) do
    %{chat: %{id: chat_id}, message_id: message_id} = message
    text = t("login.only_private")

    case reply_message(chat_id, message_id, text) do
      {:ok, sended_message} ->
        Cleaner.delete_message(chat_id, sended_message.message_id, delay_seconds: 8)

      e ->
        Logger.error("Error in response to `/login` command. Details: #{inspect(e)}")
    end

    Cleaner.delete_message(chat_id, message_id)

    {:ok, %{state | deleted: true}}
  end

  @spec make_markup(String.t()) :: InlineKeyboardMarkup.t()
  defp make_markup(token) do
    root_url = Application.get_env(:policr_mini, PolicrMiniWeb)[:root_url]

    %InlineKeyboardMarkup{
      inline_keyboard: [
        [%InlineKeyboardButton{text: t("login.btn_text"), url: "#{root_url}admin?token=#{token}"}]
      ]
    }
  end

  @spec is_admin(integer()) :: boolean()
  defp is_admin(user_id) do
    list = PermissionBusiness.find_list(user_id: user_id)

    length(list) > 0
  end
end
