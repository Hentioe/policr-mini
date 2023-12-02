defmodule PolicrMiniWeb.Admin.API.ProfileController do
  @moduledoc """
  全局属性的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.DefaultsServer
  alias PolicrMiniBot.ImageProvider

  require Logger

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    # 此 API 调用无需系统权限。
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
         {:ok, _} <- uploaded_check(zip.path),
         {:ok, unziped_albums_dir} <- unzip_albulms(zip.path) do

      temp_albums_dir = ImageProvider.temp_albums_root()

      if File.exists?(temp_albums_dir) do
        # 删除临时图集目录
        Logger.debug("Removing temp albums directory: #{inspect(temp_albums_dir)}")

        File.rm_rf!(temp_albums_dir)
      end

      try do
        # 复制解压后的图集到临时图集目录
        File.cp_r!(unziped_albums_dir, temp_albums_dir)

        render(conn, "result.json", %{ok: true})
      rescue
        e ->
          Logger.error("Processing uploaded albums failed: #{inspect(exception: e)}")

          render(conn, "result.json", %{ok: false})
      end
    end
  end

  defp unzip_albulms(zip_path) do
    unzip_cwd = Path.dirname(zip_path)

    unziped_albums_dir = Path.join(unzip_cwd, "_albums")

    if File.exists?(unziped_albums_dir) do
      # 先删除 cwd 目录中的旧解压图集，再进行解压。
      Logger.debug("Removing old unziped albums directory: #{inspect(unziped_albums_dir)}")

      File.rm_rf!(unziped_albums_dir)
    end

    case :zip.unzip(String.to_charlist(zip_path), cwd: String.to_charlist(unzip_cwd)) do
      {:ok, _} -> {:ok, unziped_albums_dir}

      e -> e
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
    # 上传图集不仅会重启图片提供服务，还会在恰当的时机停止和启动更新处理器，以避免验证受到影响。
    updates_handler = PolicrMiniBot.Supervisor.updates_handler()

    try do
      with {:ok, _} <- check_sys_permissions(conn) do
        if File.exists?(ImageProvider.temp_albums_root()) do
          :ok = Supervisor.terminate_child(PolicrMiniBot.Supervisor, updates_handler)
          :ok = Supervisor.terminate_child(PolicrMiniBot.Supervisor, ImageProvider)

          File.rm_rf!(ImageProvider.albums_root())
          File.rename!(ImageProvider.temp_albums_root(), ImageProvider.albums_root())

          {:ok, _} = Supervisor.restart_child(PolicrMiniBot.Supervisor, ImageProvider)
          {:ok, _} = Supervisor.restart_child(PolicrMiniBot.Supervisor, updates_handler)

          render(conn, "result.json", %{ok: true})
        else
          render(conn, "result.json", %{ok: false})
        end
      end
    rescue
      e ->
        Logger.error("Deployment of albums failed: #{inspect(error: e)}")

        Supervisor.restart_child(PolicrMiniBot.Supervisor, ImageProvider)
        Supervisor.restart_child(PolicrMiniBot.Supervisor, updates_handler)

        render(conn, "result.json", %{ok: false})
    end
  end
end
