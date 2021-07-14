defmodule PolicrMiniWeb.Admin.API.ProfileController do
  @moduledoc """
  全局属性的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.{Logger, DefaultsServer}
  alias PolicrMiniBot.{ImageProvider, UpdatesPoller}

  action_fallback(PolicrMiniWeb.API.FallbackController)

  def index(conn, _params) do
    # 此 API 调用无需系统权限
    scheme = DefaultsServer.get_scheme()
    manifest = ImageProvider.manifest()
    temp_manifest = ImageProvider.gen_manifest(ImageProvider.temp_albums_root())

    render(conn, "index.json", %{
      scheme: scheme,
      manifest: manifest,
      temp_manifest: temp_manifest
    })
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
      File.rm_rf!(ImageProvider.temp_albums_root())

      render(conn, "result.json", %{ok: true})
    end
  end

  def upload_temp_albums(conn, %{"zip" => %{content_type: content_type} = zip} = _params)
      when content_type == "application/zip" do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, _} <- uploaded_check(zip.path) do
      unzip_cwd = Path.dirname(zip.path)

      {:ok, _} = :zip.unzip(String.to_charlist(zip.path), cwd: String.to_charlist(unzip_cwd))

      if File.exists?(ImageProvider.temp_albums_root()) do
        File.rm_rf!(ImageProvider.temp_albums_root())
      end

      try do
        File.cp_r!(Path.join(unzip_cwd, "_albums"), ImageProvider.temp_albums_root())

        render(conn, "result.json", %{ok: true})
      rescue
        e ->
          Logger.unitized_error("Resources upload", returns: e)

          render(conn, "result.json", %{ok: false})
      end
    end
  end

  defp uploaded_check(path) do
    zip_file = Unzip.LocalFile.open(path)

    case Unzip.new(zip_file) do
      {:ok, unzip} ->
        file_names = unzip |> Unzip.list_entries() |> Enum.map(fn entry -> entry.file_name end)

        if Enum.member?(file_names, "_albums/") &&
             Enum.member?(file_names, "_albums/Manifest.yaml") do
          {:ok, []}
        else
          {:error, %{description: "wrong resources package structure"}}
        end

      _ ->
        {:error, %{description: "unzip failed"}}
    end
  end

  def update_albums(conn, _parms) do
    try do
      with {:ok, _} <- check_sys_permissions(conn) do
        if File.exists?(ImageProvider.temp_albums_root()) do
          :ok = Supervisor.terminate_child(PolicrMiniBot.Supervisor, UpdatesPoller)

          :ok = Supervisor.terminate_child(PolicrMiniBot.Supervisor, ImageProvider)

          File.rm_rf!(ImageProvider.albums_root())
          File.rename!(ImageProvider.temp_albums_root(), ImageProvider.albums_root())

          {:ok, _} = Supervisor.restart_child(PolicrMiniBot.Supervisor, ImageProvider)
          {:ok, _} = Supervisor.restart_child(PolicrMiniBot.Supervisor, UpdatesPoller)

          render(conn, "result.json", %{ok: true})
        else
          render(conn, "result.json", %{ok: false})
        end
      end
    rescue
      e ->
        Logger.unitized_error("Albums update", exception: e)

        Supervisor.restart_child(PolicrMiniBot.Supervisor, ImageProvider)
        Supervisor.restart_child(PolicrMiniBot.Supervisor, UpdatesPoller)

        render(conn, "result.json", %{ok: false})
    end
  end
end
