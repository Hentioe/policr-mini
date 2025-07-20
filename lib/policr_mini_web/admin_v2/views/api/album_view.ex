defmodule PolicrMiniWeb.AdminV2.API.AlbumView do
  use PolicrMiniWeb, :admin_v2_view

  alias Capinde.Payload.Manifest.Album

  def render("album.json", %{album: album}) when is_struct(album, Album) do
    %{
      id: album.id,
      name: album.name
    }
  end
end
