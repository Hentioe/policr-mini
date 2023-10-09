defmodule PolicrMiniBot.HookHandler do
  @moduledoc false

  use Telegex.Hook.GenHandler

  @impl true
  def on_boot do
    # Initialize the bot.
    bot_info = PolicrMiniBot.init()
    # read some parameters from your env config
    env_config = Application.get_env(:policr_mini, __MODULE__)
    # delete the webhook and set it again
    {:ok, true} = Telegex.delete_webhook()
    # set the webhook (url and secret token)
    secret_token = Telegex.Tools.gen_secret_token()
    {:ok, true} = Telegex.set_webhook(env_config[:webhook_url], secret_token: secret_token)
    # specify port for web server
    # port has a default value of 4000, but it may change with library upgrades
    config = %Telegex.Hook.Config{
      server_port: env_config[:server_port],
      secret_token: secret_token
    }

    Logger.info("Bot (@#{bot_info.username}) is working (webhook)")

    config
    # you must return the `Telegex.Hook.Config` struct ↑
  end

  @impl true
  def on_update(update) do
    # Consume the update
    PolicrMiniBot.ChainHandler.call(update, %PolicrMiniBot.ChainContext{
      bot: Telegex.Instance.bot()
    })
  end
end
