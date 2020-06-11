defmodule PolicrMini.Bot.StartCommander do
  use PolicrMini.Bot.Commander

  command(:start)

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message
    send_message(chat_id, "抱歉，我还未成熟，揣测不出您想干嘛。")

    {:ok, state}
  end
end
