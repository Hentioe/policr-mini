defmodule PolicrMini.Bot.ImageProvider do
  @moduledoc """
  实现图片提供服务的模块。
  """

  use Agent

  defmodule SeriesImage do
    defstruct [:name_zh_hans, :files]

    @type t :: %__MODULE__{
            name_zh_hans: String.t(),
            files: [String.t()]
          }
  end

  @metadata_fname "metadata.json"

  def start_link(_) do
    root_path = Application.get_env(:policr_mini, __MODULE__)[:path]

    root_metadata_path = Path.join(root_path, @metadata_fname)
    root_metadata = File.read!(root_metadata_path) |> Jason.decode!()

    include_formats =
      root_metadata["include_formats"] ||
        raise "The `#{@metadata_fname}` file is missing the `include_formats` field"

    scan_images = fn ->
      # 获取根目录中的目录列表
      series_dirs =
        File.ls!(root_path)
        # 将文件名转换为路径
        |> Enum.map(fn dir -> root_path |> Path.join(dir) end)
        # 过滤掉不是目录的文件
        |> Enum.filter(fn path -> path |> File.dir?() end)
        # 过滤掉不存在元数据文件的目录
        |> Enum.filter(fn path -> File.exists?(Path.join(path, @metadata_fname)) end)
        # 过滤掉文件数量只有一个的目录
        |> Enum.filter(fn path -> length(File.ls!(path)) > 1 end)
        # 过滤掉不包含图片的目录
        # TODO: 用日志警告不存在图片的目录。
        |> Enum.filter(fn path -> image_count(File.ls!(path), include_formats) > 0 end)

      # 遍历每个目录中的图片和元数据文件，生成 `SeriesImage` 结构
      series_images =
        series_dirs
        |> Enum.map(fn path ->
          files =
            path
            |> File.ls!()
            |> Enum.filter(fn f -> f |> image?(include_formats) end)
            |> Enum.map(fn f -> path |> Path.join(f) end)

          metadata = path |> Path.join(@metadata_fname) |> File.read!() |> Jason.decode!()

          %SeriesImage{
            files: files,
            name_zh_hans: metadata["name_zh_hans"]
          }
        end)
        |> Enum.filter(fn si -> si.name_zh_hans end)

      series_images
    end

    Agent.start_link(scan_images, name: __MODULE__)
  end

  @spec random(integer()) :: [SeriesImage.t()]
  @doc """
  随机提供指定数量的系列图片。
  """
  def random(count) do
    Agent.get(__MODULE__, fn state -> state |> Enum.take_random(count) end)
  end

  @spec image_count([String.t() | Path.t()], [String.t()]) :: integer()
  @doc """
  根据文件的名称和格式限定计算图片文件的数量。
  """
  def image_count(files, include_formats) do
    files
    |> Enum.filter(fn f -> image?(f, include_formats) end)
    |> length()
  end

  @spec image?(String.t(), [String.t()]) :: boolean()
  @doc """
  根据文件名称和限定格式判断是否为图片。
  """
  def image?(fname, include_formats) do
    Enum.member?(include_formats, String.slice(Path.extname(fname), 1..-1))
  end
end
