defmodule PolicrMiniBot.PollingHandler do
  @moduledoc false

  use Telegex.Polling.Handler

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
    {:ok, user} = Telegex.Instance.get_me()
    # Delete any potential webhook
    {:ok, true} = Telegex.delete_webhook()
    # Output startup logs
    Logger.info("Bot (@#{user.username}) is working (polling)")

    # Create configuration (can be empty, because there are default values)
    %Telegex.Polling.Config{allowed_updates: @allowed_updates}
    # You must return the `Telegex.Polling.Config` struct ↑
  end

  @impl true
  def on_update(update) do
    # Consume the update
    PolicrMiniBot.ChainHandler.call(update, %PolicrMiniBot.ChainContext{
      bot: Telegex.Instance.me()
    })
  end
end
