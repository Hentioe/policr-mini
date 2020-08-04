defmodule PolicrMiniBot.PingCommander do
  @moduledoc """
  ping 命令。
  """

  use PolicrMiniBot, plug: [commander: :ping]

  alias PolicrMini.Logger

  @impl true
  def handle(message, state) do
    %{message_id: message_id, chat: %{id: chat_id}} = message

    Cleaner.delete_message(chat_id, message_id)

    case send_message(chat_id, "🏓") do
      {:ok, sended_message} ->
        Cleaner.delete_message(chat_id, sended_message.message_id, delay_seconds: 8)

      e ->
        Logger.unitized_error("Command response", command: "/ping", returns: e)
    end

    {:ok, %{state | deleted: true}}
  end
end
