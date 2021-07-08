defmodule PolicrMiniWeb.Admin.API.ProfileView do
  @moduledoc """
  渲染后台全局属性数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()

  def render("index.json", %{scheme: scheme, manifest: manifest, temp_manifest: temp_manifest}) do
    scheme = render_one(scheme, PolicrMiniWeb.Admin.API.SchemeView, "scheme.json")

    manifest = render("manifest.json", %{manifest: manifest})
    temp_manifest = render("manifest.json", %{manifest: temp_manifest})

    %{
      scheme: scheme,
      manifest: manifest,
      temp_manifest: temp_manifest
    }
  end

  def render("result.json", %{ok: ok}) do
    %{
      ok: ok
    }
  end

  def render("manifest.json", %{manifest: manifest}) do
    if manifest do
      albums_count = length(manifest.albums)

      images_count =
        Enum.reduce(manifest.albums, 0, fn album, acc -> acc + length(album.images) end)

      manifest
      |> Map.drop([:width, :include_formats, :albums])
      |> Map.put(:albums_count, albums_count)
      |> Map.put(:images_count, images_count)
      |> Map.from_struct()
    end
  end
end
