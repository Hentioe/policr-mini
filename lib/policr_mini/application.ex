defmodule PolicrMini.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
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

    children =
      if PolicrMini.mix_env() == :test,
        do: children,
        else: children ++ [PolicrMiniBot.Supervisor]

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
end
