defmodule PolicrMini.DBServer do
  @moduledoc """
  提供线上操作数据库的服务。

  启动此服务将自动执行迁移任务。
  """

  use GenServer

  def start_link(_opts) do
    migrate()

    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
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
