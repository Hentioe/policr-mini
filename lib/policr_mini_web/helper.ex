defmodule PolicrMiniWeb.Helper do
  @moduledoc false

  alias PolicrMini.PermissionBusiness

  alias PolicrMini.Logger

  @type perm :: PermissionBusiness.permission()

  @doc """
  检查当前连接中的用户是否具备系统权限。

  如果是机器人拥有者，将返回完整的读写权。
  """
  @spec check_sys_permissions(Plug.Conn.t(), [perm]) :: {:error, map} | {:ok, [perm]}
  def check_sys_permissions(%Plug.Conn{} = conn, requires \\ []) do
    %{assigns: %{user: %{id: user_id}}} = conn

    perms =
      if user_id == Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id] do
        [:writable, :readable]
      else
        []
      end

    match_permissions(perms, requires)
  end

  @doc """
  检查当前连接中的用户是否具备目标群组的权限。
  """
  @spec check_permissions(Plug.Conn.t(), integer, [perm]) :: {:ok, [perm]} | {:error, map}
  def check_permissions(%Plug.Conn{} = conn, chat_id, requires \\ []) do
    %{assigns: %{user: %{id: user_id}}} = conn

    perms = PermissionBusiness.has_permissions(chat_id, user_id)

    match_permissions(perms, requires)
  end

  @spec match_permissions([perm], [perm]) :: {:ok, [perm]} | {:error, map}
  defp match_permissions(perms, requires) do
    missing_perms = Enum.filter(requires, fn p -> !Enum.member?(perms, p) end)

    cond do
      Enum.empty?(perms) ->
        {:error, %{description: "does not have any permissions"}}

      !Enum.empty?(missing_perms) ->
        {:error, %{description: "required permissions are missing"}}

      true ->
        {:ok, perms}
    end
  end

  @fallback_photo "/images/telegram-x128.png"

  @doc """
  获取 Telegram 服务器的图片。

  通过此函数获取的图片会缓存到本地，并返回静态资源的路径。如果没有获取到远程图片，将返回后备图片。
  """
  @spec get_photo_assets(binary) :: String.t()
  def get_photo_assets(file_id) do
    photo =
      case Cachex.fetch(:photo, file_id, &photo_fetcher/1) do
        {:ok, assets_file} ->
          assets_file

        {:commit, assets_file} ->
          assets_file

        _ ->
          @fallback_photo
      end

    Cachex.expire(:photo, file_id, :timer.hours(2))

    photo
  end

  @spec photo_fetcher(binary) :: {:commit, String.t()}
  defp photo_fetcher(file_id) do
    case Telegex.get_file(file_id) do
      {:ok, %{file_path: file_path}} ->
        file_url = "https://api.telegram.org/file/bot#{Telegex.Config.token()}/#{file_path}"

        {:commit, fetch_assets_file(file_url)}

      _ ->
        {:commit, @fallback_photo}
    end
  end

  @download_options [timeout: 1000 * 5, recv_timeout: 1000 * 15]

  @spec fetch_assets_file(binary) :: String.t()
  defp fetch_assets_file(file_url) do
    case HTTPoison.get(file_url, [], @download_options) do
      {:ok, %HTTPoison.Response{headers: headers, body: body}} ->
        if etag = Enum.find(headers, fn {header, _} -> header == "ETag" end) do
          filename =
            "photo_cache_" <> (etag |> elem(1) |> String.slice(1..-2)) <> Path.extname(file_url)

          fetch_from_local(filename, body)
        else
          @fallback_photo
        end

      e ->
        Logger.unitized_error("Photo download", e)

        @fallback_photo
    end
  end

  @spec fetch_from_local(binary, iodata) :: String.t()
  defp fetch_from_local(filename, data) do
    assets_file = "#{Application.app_dir(:policr_mini, "priv/static/images")}/#{filename}"

    if File.exists?(assets_file) do
      "/images/#{filename}"
    else
      case File.write(assets_file, data) do
        :ok ->
          "/images/#{filename}"

        e ->
          Logger.unitized_error("Photo writing", e)

          @fallback_photo
      end
    end
  end
end
