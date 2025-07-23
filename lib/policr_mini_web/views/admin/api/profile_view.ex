defmodule PolicrMiniWeb.Admin.API.ProfileView do
  @moduledoc false

  use PolicrMiniWeb, :view

  def render("index.json", %{scheme: scheme}) do
    scheme = render_one(scheme, PolicrMiniWeb.Admin.API.SchemeView, "scheme.json")

    %{
      scheme: scheme
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

  def render("album.json", %{album: album}) do
    %{
      id: album.id,
      name: album.name
    }
  end
end
