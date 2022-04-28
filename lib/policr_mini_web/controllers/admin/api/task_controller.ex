defmodule PolicrMiniWeb.Admin.API.TaskController do
  @moduledoc """
  定时如的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMiniBot.Runner

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      jobs = Runner.jobs()

      render(conn, "index.json", %{jobs: jobs})
    end
  end
end
