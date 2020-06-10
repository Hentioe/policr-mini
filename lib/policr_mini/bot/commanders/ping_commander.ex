defmodule PolicrMini.Bot.PingCommander do
  use PolicrMini.Bot.Commander

  command(:ping)

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message
    Nadia.send_message(chat_id, "🏓")

    {:ok, state}
  end
end
