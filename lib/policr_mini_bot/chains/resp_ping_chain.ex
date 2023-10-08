defmodule PolicrMiniBot.RespPingChain do
  @moduledoc """
  `/ping` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :ping}

  alias PolicrMiniBot.Worker

  require Logger

  @impl true
  def handle(message, context) do
    %{message_id: message_id, chat: chat} = message

    Worker.async_delete_message(chat.id, message_id)

    case send_text(chat.id, "🏓") do
      {:ok, %{message_id: message_id}} ->
        Worker.async_delete_message(chat.id, message_id, delay_secs: 8)

      {:error, reason} ->
        Logger.error("Command response failed: #{inspect(command: "/ping", reason: reason)}",
          chat_id: chat.id
        )
    end

    {:stop, %{context | deleted: true}}
  end
end
