defmodule PolicrMini.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    # 输出构建时/运行时信息。
    print_buildtime_runtime_info()

    PolicrMini.Mnesia.init()
    PolicrMini.Worker.GeneralRun.init_queue()

    config = Application.get_env(:policr_mini, __MODULE__)

    runtime_migrate? = config[:runtime_migrate] || false
    tg_serve? = config[:tg_serve] || false

    children =
      []
      # Start the Ecto repository
      |> serve_children(PolicrMini.Repo, true)
      # Start the Cacher
      |> serve_children(PolicrMini.Cache, true)
      # Start the runtime migrator
      |> serve_children(PolicrMini.DBServer, runtime_migrate?)
      # Start the Counter
      |> serve_children(PolicrMini.Counter, true)
      # Start the defaults server
      |> serve_children(PolicrMini.DefaultsServer, true)
      # Start the Telemetry supervisor
      |> serve_children(PolicrMiniWeb.Telemetry, true)
      # Start the PubSub system
      |> serve_children({Phoenix.PubSub, name: PolicrMini.PubSub}, true)
      # Start the Endpoint (http/https)
      |> serve_children(PolicrMiniWeb.Endpoint, true)
      # Start the Telegram bot
      |> serve_children(PolicrMiniBot.Supervisor, tg_serve?)

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

  defp serve_children(children, child, server?) do
    children ++
      if server? do
        [child]
      else
        []
      end
  end

  defp print_buildtime_runtime_info do
    alias PolicrMini.BuildtimeRuntime.Tools

    Logger.info(
      "Buildtime/Runtime: [otp-#{Tools.otp_version()}, elixir-#{Tools.elixir_version()}] / [erts-#{Tools.erts_version()}]"
    )
  end
end
