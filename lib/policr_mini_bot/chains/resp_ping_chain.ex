defmodule PolicrMiniBot.RespPingChain do
  @moduledoc """
  `/ping` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :ping}

  require Logger

  @impl true
  def handle(message, context) do
    %{message_id: message_id, chat: chat} = message

    async_delete_message(chat.id, message_id)

    case send_text(chat.id, "🏓") do
      {:ok, %{message_id: message_id}} ->
        async_delete_message_after(chat.id, message_id, 8)

      {:error, reason} ->
        Logger.error("Command response failed: #{inspect(command: "/ping", reason: reason)}",
          chat_id: chat.id
        )
    end

    {:stop, %{context | deleted: true}}
  end
end
