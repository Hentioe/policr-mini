defmodule PolicrMiniWeb.Helper do
  @moduledoc false

  alias PolicrMini.PermissionBusiness

  alias PolicrMini.Logger

  @doc """
  检查当前连接中的用户是否具备目标群组的权限。
  """
  @spec check_permissions(Plug.Conn.t(), integer, [PermissionBusiness.permission()]) ::
          {:ok, [atom]} | {:error, map}
  def check_permissions(
        %Plug.Conn{assigns: %{user: %{id: user_id}}} = _conn,
        chat_id,
        requires \\ []
      ) do
    permissions = PermissionBusiness.has_permissions(chat_id, user_id)
    missings = Enum.filter(requires, fn p -> !Enum.member?(permissions, p) end)

    cond do
      Enum.empty?(permissions) ->
        {:error, %{description: "does not have any permissions"}}

      !Enum.empty?(missings) ->
        {:error, %{description: "required permissions are missing"}}

      true ->
        {:ok, permissions}
    end
  end

  @fallback_photo "/images/telegram-x128.png"

  @doc """
  获取 Telegram 服务器的图片。

  通过此函数获取的图片会缓存到本地，并返回静态资源的路径。如果没有获取到远程图片，将返回后备图片。
  """
  @spec get_photo(binary) :: String.t()
  def get_photo(file_id) do
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
        Logger.error("An error occurred while download the photo. Details: #{inspect(e)}")

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
          Logger.error("An error occurred while writing the photo. Details: #{inspect(e)}")

          @fallback_photo
      end
    end
  end
end
