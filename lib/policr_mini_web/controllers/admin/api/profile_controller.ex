defmodule PolicrMiniWeb.Admin.API.ProfileController do
  @moduledoc """
  全局属性的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.DefaultsServer

  require Logger

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    # 此 API 调用无需系统权限
    scheme = DefaultsServer.get_scheme()

    with {:ok, deployed_info} <- Capinde.deployed() do
      uploaded = Capinde.uploaded()

      render(conn, "index.json", %{
        scheme: scheme,
        deployed_info: deployed_info,
        uploaded: uploaded
      })
    end
  end

  def update_scheme(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         :ok <- DefaultsServer.update_scheme(params) do
      # TODO: 配合 `PolicrMini.DefaultsServer` 模块以支持返回错误消息。

      render(conn, "result.json", %{ok: true})
    end
  end

  def delete_uploaded(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, _} <- Capinde.delete_uploaded() do
      render(conn, "result.json", %{ok: true})
    end
  end

  def upload_albums(conn, %{"archive" => %{content_type: content_type} = archive} = _params)
      when content_type == "application/zip" do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, archive_info} <- Capinde.upload(archive.path) do
      render(conn, "archive_info.json", %{archive_info: archive_info})
    end
  end

  def deploy_albums(conn, _parms) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, _} <- Capinde.deploy_uploaded() do
      render(conn, "result.json", %{ok: true})
    end
  end
end
