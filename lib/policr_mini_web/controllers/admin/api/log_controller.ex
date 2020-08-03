defmodule PolicrMiniWeb.Admin.API.LogController do
  @moduledoc """
  和持久化存储的日志相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.Logger

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      logs = Logger.query()

      render(conn, "index.json", %{logs: logs, ending: true})
    end
  end
end
