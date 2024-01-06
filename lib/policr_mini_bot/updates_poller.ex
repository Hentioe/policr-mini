defmodule PolicrMiniBot.UpdatesPoller do
  @moduledoc false

  use Telegex.GenPoller

  @impl true
  def on_boot do
    # Initialize the bot.
    bot_info = PolicrMiniBot.init()
    # Delete any potential webhook
    {:ok, true} = Telegex.delete_webhook()
    # Output startup logs
    Logger.info("Bot (@#{bot_info.username}) is working (polling)")

    # Create configuration (can be empty, because there are default values)
    %Telegex.Polling.Config{allowed_updates: PolicrMiniBot.allowed_updates()}
    # You must return the `Telegex.Polling.Config` struct ↑
  end

  @impl true
  def on_update(update) do
    # Consume the update
    PolicrMiniBot.ChainHandler.call(update, %PolicrMiniBot.ChainContext{
      bot: Telegex.Instance.bot()
    })
  end

  @impl true
  def on_failure(update, {e, stacktrace}) do
    import PolicrMiniBot.Helper.FromParser

    chat_id = parse_chat_id(update)

    Logger.error(
      "Uncaught Error: #{inspect(exception: e)}\n#{Exception.format(:error, e, stacktrace)}",
      chat_id: chat_id
    )
  end
end
