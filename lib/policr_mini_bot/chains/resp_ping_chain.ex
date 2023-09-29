defmodule PolicrMiniBot.RespPingChain do
  @moduledoc """
  `/ping` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :ping}

  alias PolicrMiniBot.Worker

  require Logger

  @impl true
  def handle(message, context) do
    %{message_id: message_id, chat: %{id: chat_id}} = message

    Worker.async_delete_message(chat_id, message_id)

    case send_text(chat_id, "🏓") do
      {:ok, %{message_id: message_id}} ->
        Worker.async_delete_message(chat_id, message_id, delay_secs: 8)

      {:error, reason} ->
        Logger.error("Command response failed: #{inspect(command: "/ping", reason: reason)}")
    end

    {:ok, %{context | deleted: true}}
  end
end
