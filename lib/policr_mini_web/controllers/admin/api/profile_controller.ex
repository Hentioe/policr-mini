defmodule PolicrMiniWeb.Admin.API.ProfileController do
  @moduledoc """
  全局属性的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.{Logger, DefaultsServer}
  alias PolicrMiniBot.ImageProvider

  action_fallback(PolicrMiniWeb.API.FallbackController)

  @temp_albums_root Application.app_dir(:policr_mini, Path.join("priv", "_temp_albums"))

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      scheme = DefaultsServer.get_scheme()
      manifest = ImageProvider.manifest()
      temp_manifest = ImageProvider.gen_manifest(@temp_albums_root)

      render(conn, "index.json", %{
        scheme: scheme,
        manifest: manifest,
        temp_manifest: temp_manifest
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

  def delete_temp_albums(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      File.rm_rf!(@temp_albums_root)

      render(conn, "result.json", %{ok: true})
    end
  end

  def update_albums(conn, _parms) do
    alias PolicrMiniBot.{UpdatesPoller, ImageProvider}

    with {:ok, _} <- check_sys_permissions(conn) do
      if File.exists?(@temp_albums_root) do
        try do
          :ok = Supervisor.terminate_child(PolicrMiniBot.Supervisor, UpdatesPoller)

          :ok = Supervisor.terminate_child(PolicrMiniBot.Supervisor, ImageProvider)

          File.rm_rf!(ImageProvider.albums_root_path())
          File.rename!(@temp_albums_root, ImageProvider.albums_root_path())

          {:ok, _} = Supervisor.restart_child(PolicrMiniBot.Supervisor, ImageProvider)
          {:ok, _} = Supervisor.restart_child(PolicrMiniBot.Supervisor, UpdatesPoller)

          render(conn, "result.json", %{ok: true})
        rescue
          e ->
            Logger.unitized_error("Albums update", exception: e)

            Supervisor.restart_child(PolicrMiniBot.Supervisor, ImageProvider)
            Supervisor.restart_child(PolicrMiniBot.Supervisor, UpdatesPoller)

            render(conn, "result.json", %{ok: false})
        end
      else
        render(conn, "result.json", %{ok: false})
      end
    end
  end
end
