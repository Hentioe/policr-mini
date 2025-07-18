defmodule PolicrMiniWeb.Admin.API.ProfileView do
  @moduledoc """
  渲染后台全局属性数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()

  def render("index.json", %{scheme: scheme, deployed_info: deployed_info, uploaded: uploaded}) do
    scheme = render_one(scheme, PolicrMiniWeb.Admin.API.SchemeView, "scheme.json")
    deployed_info = render("deployed_info.json", %{deployed_info: deployed_info})

    uploaded =
      case uploaded do
        {:ok, archive_info} -> render("archive_info.json", %{archive_info: archive_info})
        {:error, _} -> nil
      end

    %{
      scheme: scheme,
      deployed_info: deployed_info,
      uploaded: uploaded
    }
  end

  def render("result.json", %{ok: ok}) do
    %{
      ok: ok
    }
  end

  def render("manifest.json", %{manifest: manifest}) do
    %{
      version: manifest.version,
      datetime: manifest.datetime,
      include_formats: manifest.include_formats,
      albums: render_many(manifest.albums, __MODULE__, "album.json", as: :album)
    }
  end

  def render("archive_info.json", %{archive_info: archive_info}) do
    manifest = render("manifest.json", %{manifest: archive_info.manifest})

    %{
      manifest: manifest,
      total_images: archive_info.total_images
    }
  end

  def render("deployed_info.json", %{deployed_info: deployed_info}) do
    manifest = render("manifest.json", %{manifest: deployed_info.manifest})

    %{
      manifest: manifest,
      total_images: deployed_info.total_images
    }
  end

  def render("album.json", %{album: album}) do
    %{
      id: album.id,
      name: album.name
    }
  end
end
