defmodule PolicrMiniWeb.AdminV2.API.ManifestView do
  use PolicrMiniWeb, :admin_v2_view

  alias Capinde.Payload.Manifest

  def render("manifest.json", %{manifest: manifest}) when is_struct(manifest, Manifest) do
    %{
      version: manifest.version,
      datetime: manifest.datetime,
      include_formats: manifest.include_formats,
      albums: render_many(manifest.albums, PolicrMiniWeb.AdminV2.API.AlbumView, "album.json"),
      conflicts: manifest.conflicts
    }
  end
end
