defmodule PolicrMini.Bot.PingCommander do
  use PolicrMini.Bot.Commander, :ping

  require Logger

  @impl true
  def handle(message, state) do
    %{message_id: message_id, chat: %{id: chat_id}} = message

    async(fn -> Nadia.delete_message(chat_id, message_id) end)

    case send_message(chat_id, "🏓") do
      {:ok, sended_message} ->
        async(fn -> Nadia.delete_message(chat_id, sended_message.message_id) end, seconds: 8)

      e ->
        Logger.error("Error in response to `/ping` command, details: #{inspect(e)}")
    end

    {:ok, state}
  end
end
