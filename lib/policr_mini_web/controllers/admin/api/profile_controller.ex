defmodule PolicrMiniWeb.Admin.API.ProfileController do
  @moduledoc """
  全局属性的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.DefaultsServer

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    scheme = DefaultsServer.get_scheme()

    render(conn, "index.json", %{scheme: scheme})
  end

  def update_scheme(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         :ok <- DefaultsServer.update_default_scheme(params) do
      # TODO: 配合 `PolicrMini.DefaultsServer` 模块以支持返回错误消息。

      render(conn, "result.json", %{ok: true})
    end
  end
end
