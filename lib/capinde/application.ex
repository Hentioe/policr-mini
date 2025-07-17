defmodule Capinde.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: Capinde.Finch}
    ]

    opts = [strategy: :one_for_one, name: Capinde.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
