defmodule PolicrMiniBot.RespPingCmdPlug do
  @moduledoc """
  ping 命令。
  """

  use PolicrMiniBot, plug: [commander: :ping]

  alias PolicrMiniBot.Worker

  require Logger

  @impl true
  def handle(message, state) do
    %{message_id: message_id, chat: %{id: chat_id}} = message

    Worker.async_delete_message(chat_id, message_id)

    case send_text(chat_id, "🏓", logging: true) do
      {:ok, %{message_id: message_id}} ->
        Worker.async_delete_message(chat_id, message_id, delay_secs: 8)

      {:error, reason} ->
        Logger.error("Command response failed: #{inspect(command: "/ping", reason: reason)}")
    end

    {:ok, %{state | deleted: true}}
  end
end
