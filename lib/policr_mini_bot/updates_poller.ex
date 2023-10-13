defmodule PolicrMiniBot.UpdatesPoller do
  @moduledoc false

  use Telegex.GenPoller

  # 注意：当前并未依赖对编辑消息、频道消息、内联查询等更新类型的接收才能实现的功能，如有需要需提前更新此列表。
  @allowed_updates [
    "message",
    "callback_query",
    "my_chat_member",
    "chat_member",
    "chat_join_request"
  ]

  @impl true
  def on_boot do
    # Initialize the bot.
    bot_info = PolicrMiniBot.init()
    # Delete any potential webhook
    {:ok, true} = Telegex.delete_webhook()
    # Output startup logs
    Logger.info("Bot (@#{bot_info.username}) is working (polling)")

    # Create configuration (can be empty, because there are default values)
    %Telegex.Polling.Config{allowed_updates: @allowed_updates}
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
