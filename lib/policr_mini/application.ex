defmodule PolicrMini.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    # 输出 banner 消息
    print_banner()
    # 输出构建时/运行时信息
    print_buildtime_runtime_info()
    # 初始化 Mnesia 表结构。
    PolicrMini.Mnesia.init()
    # 初始化 workers。
    PolicrMini.Worker.GeneralRun.init_queue()

    config = Application.get_env(:policr_mini, __MODULE__)

    runtime_migrate? = config[:runtime_migrate] || false
    bot_serve? = config[:bot_serve] || false

    children =
      [
        # Start the Ecto repository
        PolicrMini.Repo,
        # Start the runtime migrator
        {PolicrMini.RuntimeMigrator, serve: runtime_migrate?},
        # Start the InfluxDB connection
        PolicrMini.InfluxConn,
        # Start the Finch
        {Finch, name: PolicrMini.Finch},
        # Start the Cacher
        PolicrMini.Cache,
        # Start the Counter
        PolicrMini.Counter,
        # Start the defaults server
        PolicrMini.DefaultsServer,
        # Start the Web telemetry
        PolicrMiniWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: PolicrMini.PubSub},
        # Start the Endpoint (http/https)
        PolicrMiniWeb.Endpoint,
        # Start the Telegram bot
        {PolicrMiniBot.Supervisor, serve: bot_serve?},
        # 启动后台任务的 Honeycomb 系统
        {Honeycomb, queen: PolicrMini.BackgroundQueen}
      ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PolicrMini.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PolicrMiniWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp print_buildtime_runtime_info do
    elixir_version = System.version()
    erts_version = to_string(:erlang.system_info(:version))

    Logger.info("TOOLCHAINS: [ELIXIR-#{elixir_version}, ERTS-#{erts_version}]")
  end

  defp print_banner do
    if PolicrMini.mix_env() in [:dev, :prod] do
      banner_path = Application.app_dir(:policr_mini, ["priv", "banner.txt"])
      banner = File.read!(banner_path)

      IO.write("#{banner}\n")
    end
  end
end
