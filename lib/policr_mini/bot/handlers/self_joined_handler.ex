defmodule PolicrMini.Bot.SelfJoinedHandler do
  use PolicrMini.Bot.Handler

  require Logger

  alias PolicrMini.Bot.SyncCommander

  @impl true
  def match?(%{new_chat_member: nil} = _message, state), do: {false, state}

  @impl true
  def match?(%{new_chat_member: %{id: joined_user_id}} = _message, state),
    do: {joined_user_id == bot_id(), state}

  @impl true
  def handle(message, state) do
    chat_id = message.chat.id

    # 同步群组和管理员信息
    with {:ok, chat} <- SyncCommander.synchronize_chat(chat_id, init: true),
         {:ok, _} <- SyncCommander.synchronize_administrators(chat),
         :ok <- response(chat_id) do
      {:ok, state}
    else
      e ->
        Logger.error("An error occurred after the bot was invited, details: #{inspect(e)}")
        send_message(chat_id, t("self_joined.error"))
    end

    {:ok, %{state | done: true}}
  end

  @spec response(integer()) :: :ok | {:error, Nadia.Model.Error.t()}
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

    case send_message(chat_id, text, reply_markup: markup, parse_mode: nil) do
      {:ok, _} -> :ok
      e -> e
    end
  end
end
