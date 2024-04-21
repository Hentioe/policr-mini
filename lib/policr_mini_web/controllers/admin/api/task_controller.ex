defmodule PolicrMiniWeb.Admin.API.TaskController do
  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.{Stats, StatefulTaskCenter}
  alias PolicrMiniBot.Runner

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      scheduled_jobs = Runner.jobs()
      stateful_jobs = StatefulTaskCenter.jobs()

      render(conn, "index.json", %{scheduled_jobs: scheduled_jobs, stateful_jobs: stateful_jobs})
    end
  end

  def reset_stats(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      :ok = StatefulTaskCenter.schedule(:reset_all_stats, &Stats.reset_all_stats/0)

      render(conn, "result.json", %{ok: true})
    end
  end
end
