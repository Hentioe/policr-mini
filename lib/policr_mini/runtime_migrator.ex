defmodule PolicrMini.RuntimeMigrator do
  @moduledoc false

  use GenServer

  require Logger

  def start_link(opts) do
    if Keyword.get(opts, :serve, false) do
      migrate()

      GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    else
      Logger.warning("Runtime migrator is not serving")

      :ignore
    end
  end

  def init(:ok) do
    {:ok, :ok}
  end

  defp migrate do
    repos = Application.fetch_env!(:policr_mini, :ecto_repos)

    for repo <- repos do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end
end
