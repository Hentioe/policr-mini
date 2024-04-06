defmodule PolicrMiniWeb.TgAssetsFetcher do
  @moduledoc false

  require Logger

  @fallback_photo "/images/telegram-128x128.png"

  @type photo_asset_opts :: [{:fallback, binary}]

  @doc """
  获取 Telegram 服务器的图片。

  通过此函数获取的图片会缓存到本地，并返回静态资源的路径。如果没有获取到远程图片，将返回后备图片。

  ## 参数：
  - `filed_id`: 文件 ID。如果值为 `nil` 则直接返回后备图片。
  """
  @spec get_photo(binary | nil, photo_asset_opts) :: binary
  def get_photo(file_id, opts \\ []) do
    fallback_photo = Keyword.get(opts, :fallback, @fallback_photo)

    if file_id do
      photo =
        case Cachex.fetch(:photo, file_id, &fetch_photo(&1, fallback_photo)) do
          {:ok, assets_file} ->
            assets_file

          {:commit, assets_file} ->
            assets_file

          _ ->
            fallback_photo
        end

      Cachex.expire(:photo, file_id, :timer.hours(1))

      photo
    else
      fallback_photo
    end
  end

  @spec fetch_photo(binary, binary) :: {:commit, String.t()}
  defp fetch_photo(file_id, fallback_photo) do
    case Telegex.get_file(file_id) do
      {:ok, %{file_path: file_path}} ->
        relative_path =
          if String.starts_with?(file_path, "/") do
            String.slice(file_path, 1..-1//1)
          else
            file_path
          end

        file_url =
          "#{Telegex.Global.api_base_url()}/file/bot#{Telegex.Instance.token()}/#{relative_path}"

        {:commit, fetch_assets_file(file_url, fallback_photo)}

      _ ->
        {:commit, fallback_photo}
    end
  end

  @fetch_options [receive_timeout: 15 * 1000]

  @spec fetch_assets_file(binary, binary) :: String.t()
  defp fetch_assets_file(file_url, fallback_photo) do
    etag_finder = fn {header, _} -> header == "etag" end

    fetch_fun = fn %{headers: headers, body: body} ->
      if etag = Enum.find(headers, etag_finder) do
        filename =
          "photo_cache_" <> (etag |> elem(1) |> String.slice(1..-2//1)) <> Path.extname(file_url)

        fetch_from_local(filename, body, fallback_photo)
      else
        fallback_photo
      end
    end

    case :get |> Finch.build(file_url) |> Finch.request(PolicrMini.Finch, @fetch_options) do
      {:ok, %Finch.Response{} = response} ->
        fetch_fun.(response)

      {:error, reason} ->
        Logger.error("Photo download failed: #{inspect(reason: reason, url: file_url)}")

        fallback_photo
    end
  end

  @spec fetch_from_local(binary, iodata, binary) :: String.t()
  defp fetch_from_local(filename, data, fallback_photo) do
    assets_file = "#{Application.app_dir(:policr_mini, "priv/static/images")}/#{filename}"

    if File.exists?(assets_file) do
      "/images/#{filename}"
    else
      case File.write(assets_file, data) do
        :ok ->
          "/images/#{filename}"

        {:error, reason} ->
          Logger.error("Photo write failed: #{inspect(reason: reason)}")

          fallback_photo
      end
    end
  end
end
