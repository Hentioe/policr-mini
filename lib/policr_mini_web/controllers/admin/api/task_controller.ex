defmodule PolicrMiniWeb.Admin.API.TaskController do
  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.Stats
  alias PolicrMiniBot.Runner

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      scheduled_jobs = Runner.jobs()
      bees = Honeycomb.bees(:background)

      render(conn, "index.json", %{scheduled_jobs: scheduled_jobs, bees: bees})
    end
  end

  def reset_stats(conn, _params) do
    run = &Stats.reset_all_stats/0

    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, bee} <- Honeycomb.brew_honey(:background, "reset_all_stats", run) do
      render(conn, "result.json", %{bee: bee})
    end
  end
end
