defmodule PolicrMini.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias PolicrMiniBot.{
    IdentityCheckPreheater,
    StartCommander,
    PingCommander,
    SyncCommander,
    SelfJoinedHandler,
    SelfLeftedHandler,
    UserJoinedHandler,
    NewChatTitleHandler,
    VerificationCaller
  }

  def start(_type, _args) do
    install_plugs([IdentityCheckPreheater])
    install_plugs([StartCommander, PingCommander, SyncCommander])
    install_plugs([SelfJoinedHandler, SelfLeftedHandler, UserJoinedHandler, NewChatTitleHandler])
    install_plugs([VerificationCaller])

    children = [
      # Start the Ecto repository
      PolicrMini.Repo,
      # Start the Telemetry supervisor
      PolicrMiniWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PolicrMini.PubSub},
      # Start the Endpoint (http/https)
      PolicrMiniWeb.Endpoint
    ]

    bot_children = [
      # 图片供应服务
      PolicrMiniBot.ImageProvider,
      # 消息清理服务
      PolicrMiniBot.Cleaner,
      # 拉取更新消息
      PolicrMiniBot.UpdatesPoller,
      # 消费消息的动态主管
      PolicrMiniBot.Consumer,
      # 任务调度服务
      PolicrMiniBot.Scheduler
    ]

    children =
      if PolicrMini.mix_env() == :test,
        do: children,
        else: children ++ bot_children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PolicrMini.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PolicrMiniWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp install_plugs(plugs) do
    Telegex.Plug.Pipeline.install_all(plugs)
  end
end
