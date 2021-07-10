defmodule PolicrMiniBot.ImageProvider do
  @doc """
  图片供应商。
  """

  defmodule I18nStr do
    @moduledoc false
    defstruct [:zh_hans, :zh_hant, :en]

    @type t :: %__MODULE__{
            zh_hans: binary,
            zh_hant: binary,
            en: binary
          }

    def new(%{"zh-hans" => zh_hans, "zh-hant" => zh_hant, "en" => en}) do
      %__MODULE__{
        zh_hans: zh_hans,
        zh_hant: zh_hant,
        en: en
      }
    end
  end

  defmodule Album do
    @moduledoc """
    一个图集。表示一个图片分类，在清单结构中，它包含了本类别的所有图片。
    """
    defstruct [:id, :name, :parents, :images]

    @type t :: %__MODULE__{
            id: binary,
            name: I18nStr.t(),
            parents: [binary],
            images: [binary]
          }

    def new(%{"id" => id, "name" => name, "parents" => parents}) do
      %__MODULE__{
        id: id,
        name: I18nStr.new(name),
        parents: parents
      }
    end
  end

  defmodule Manifest do
    @moduledoc false
    defstruct [:root_path, :version, :datetime, :include_formats, :width, :albums]

    @type t :: %__MODULE__{
            root_path: Path.t(),
            version: binary,
            datetime: binary,
            include_formats: [binary],
            width: integer,
            albums: [Album.t()]
          }

    def new(%{
          "version" => version,
          "datetime" => datetime,
          "include_formats" => include_formats,
          "width" => width,
          "albums" => albums
        }) do
      %__MODULE__{
        version: version,
        datetime: datetime,
        include_formats: include_formats,
        width: width,
        albums: Enum.map(albums, &Album.new/1)
      }
    end

    @doc """
    扫描并填充 albums 中的图片列表。
    """
    @spec fill_albums_images(__MODULE__.t()) :: __MODULE__.t()
    def fill_albums_images(manifest) do
      fill_images_fun = fn album ->
        images =
          PolicrMiniBot.ImageProvider.scan_images(
            manifest.root_path,
            album,
            manifest.include_formats
          )

        %{album | images: images}
      end

      albums = Enum.map(manifest.albums, fill_images_fun)

      %{manifest | albums: albums}
    end

    @doc """
    展开 albums 的所有父级，包括非直接父级（例如父级的父级）。这些父级的 ID 将放在同一个 `parents` 字段中。
    """
    def expand_albums_parents(manifest) do
      albums =
        Enum.map(manifest.albums, fn album ->
          parents = all_album_parents(manifest, album)

          %{album | parents: parents}
        end)

      %{manifest | albums: albums}
    end

    @doc """
    查找某个 album 的所有父级，包括非直接父级（例如父级的父级）。这些父级的 ID 将放在同一个类别中返回。
    """
    @spec all_album_parents(__MODULE__.t(), Album.t()) :: [binary]
    def all_album_parents(manifest, album, parents \\ []) do
      if album == nil || album.parents == nil || Enum.empty?(album.parents) do
        parents
      else
        Enum.reduce(album.parents, parents ++ album.parents, fn parent_id, acc ->
          album = find_album(manifest, parent_id)

          all_album_parents(manifest, album, acc)
        end)
      end
    end

    @spec find_album(__MODULE__.t(), binary) :: Album.t() | nil
    defp find_album(manifest, id) do
      Enum.find(manifest.albums, fn album -> album.id == id end)
    end

    @doc """
    清理没有图片的 albums。
    """
    @spec clear_empty_albums(__MODULE__.t()) :: __MODULE__.t()
    def clear_empty_albums(manifest) do
      albums = Enum.filter(manifest.albums, fn album -> length(album.images) > 0 end)

      %{manifest | albums: albums}
    end
  end

  defmodule Image do
    @moduledoc """
    单张图片。
    """

    defstruct [:name, :path]

    @type t :: %__MODULE__{
            name: binary | nil,
            path: binary
          }
  end

  use Agent

  def start_link(_) do
    manifest = gen_manifest(albums_root())

    state = %{manifest: manifest}

    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  @spec manifest() :: Manifest.t()
  def manifest() do
    get(:manifest)
  end

  def root do
    Application.get_env(:policr_mini, __MODULE__)[:root]
  end

  @spec albums_root() :: Path.t()
  def albums_root() do
    Path.join(root(), "_albums")
  end

  @spec temp_albums_root() :: Path.t()
  def temp_albums_root() do
    Path.join(root(), "_temp_albums")
  end

  defp get(field) do
    Agent.get(__MODULE__, fn state -> state[field] end)
  end

  @doc """
  生成清单。从指定目录中读取 `Manifest.yaml` 并反序列化为 Manifest 结构。
  """
  @spec gen_manifest(Path.t()) :: Manifest.t()
  def gen_manifest(path) do
    file = Path.join(path, "Manifest.yaml")

    if File.exists?(file) do
      yaml = YamlElixir.read_from_file!(Path.join(path, "Manifest.yaml"))

      yaml
      |> Manifest.new()
      |> Map.put(:root_path, path)
      |> Manifest.fill_albums_images()
      |> Manifest.clear_empty_albums()
      |> Manifest.expand_albums_parents()
    else
      nil
    end
  end

  @doc """
  生成无图集冲突图片列表。

  注意：如果生成不了指定的最大数量（例如图集数量不够，或者满足不冲突关系的图集数量不够），将会返回小于指定的最大数量的图片列表。
  """
  @spec bomb(integer) :: [Image.t()]
  def bomb(max_count) do
    Agent.get(__MODULE__, &gen_strategy(&1, max_count))
  end

  defp gen_strategy(%{manifest: nil}, _max_count) do
    []
  end

  defp gen_strategy(%{manifest: manifest}, max_count) do
    manifest.albums
    |> conflict_free_gen(max_count)
    |> Enum.map(fn album ->
      image = Enum.random(album.images)

      %{image | name: album.name}
    end)
  end

  @spec conflict_free_gen([Album.t()], integer) :: [Album.t()]
  defp conflict_free_gen(albums, max_count, results \\ []) do
    if max_count == 0 || Enum.empty?(albums) do
      results
    else
      current = Enum.random(albums)

      albums = albums -- [current]

      albums =
        Enum.filter(albums, fn album ->
          # 避免冲突的条件：
          # - 排除剩余的图集的父级为当前生成的图集。
          # - 排除剩余的图集中为当前生成的图集的父级的图集。
          # - 排除剩余的图集的父级和当前生成的图集的父级有交叉。
          !Enum.member?(album.parents, current.id) &&
            !Enum.member?(current.parents, album.id) &&
            current.parents -- album.parents == current.parents
        end)

      conflict_free_gen(albums, max_count - 1, results ++ [current])
    end
  end

  @spec scan_images(Path.t(), Album.t(), [binary]) :: [Image.t()]
  def scan_images(root_path, %{id: id}, include_formats) do
    album_path = Path.join(root_path, id)

    files = File.ls!(album_path)

    format_included_fun = fn path ->
      format = path |> Path.extname() |> String.slice(1..-1)

      Enum.member?(include_formats, format)
    end

    files
    # 将文件名转换为路径。
    |> Enum.map(fn f -> Path.join(album_path, f) end)
    # 过滤掉子目录。
    |> Enum.filter(fn path -> !File.dir?(path) end)
    # 过滤掉不包含的格式。
    |> Enum.filter(format_included_fun)
    # 构造成图片结构体。
    |> Enum.map(fn path -> %Image{path: path} end)
  end
end
