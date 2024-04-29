defmodule PolicrMiniBot.Runner.CacheCleaner do
  @moduledoc false

  alias PolicrMiniBot.ImageProvider

  require Logger

  def schedule do
    Logger.debug("Start to clean cache files")

    # 生成当前时间戳
    now_unix = DateTime.to_unix(DateTime.utc_now())
    # 读取所有图片缓存文件
    cache_dir = Path.join(ImageProvider.root(), "_cache")
    files = traverse_dir(cache_dir)

    r =
      for file <- files do
        # 获取每一个文件的 atime，如果当前时间戳 - atime > 60 秒，则删除文件
        atime = stat(file)

        if now_unix - atime > 60 do
          rm(file)

          Logger.debug("Removed cache file: #{file}")

          :ok
        else
          :ignored
        end
      end

    # 日志中输出删除的文件数量
    succeeded_count = Enum.count(r, &(&1 == :ok))

    if succeeded_count > 0 do
      Logger.info("Removed #{succeeded_count} cache file(s)")
    end

    Logger.debug("Finish cleaning cache files")

    :done
  end

  defp stat(f) do
    case File.stat(f, time: :posix) do
      {:ok, %{atime: atime}} ->
        atime

      {:error, reason} ->
        Logger.error("Failed to get atime of file: #{[file: f, reason: reason]}")

        0
    end
  end

  defp rm(f) do
    case File.rm(f) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to remove file: #{[file: f, reason: reason]}")

        :error
    end
  end

  defp traverse_dir(dir, opts \\ []) do
    ignores = Keyword.get(opts, :ignores, [])

    if Enum.member?(ignores, Path.basename(dir)) do
      []
    else
      recursive_fun = fn file -> recursive_subfiles(dir, file, opts) end

      dir
      |> File.ls!()
      |> Enum.map(recursive_fun)
      |> List.flatten()
    end
  end

  defp recursive_subfiles(dir, file, opts) do
    ignores = Keyword.get(opts, :ignores, [])
    include_dirs = Keyword.get(opts, :include_dirs, false)

    path = Path.join(dir, file)

    if File.dir?(path) do
      if include_dirs do
        [path] ++ [traverse_dir(path, opts)]
      else
        traverse_dir(path, opts)
      end
    else
      if Enum.member?(ignores, file) do
        []
      else
        [path]
      end
    end
  end
end
