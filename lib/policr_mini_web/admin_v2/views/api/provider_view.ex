defmodule PolicrMiniWeb.AdminV2.API.ProviderView do
  use PolicrMiniWeb, :admin_v2_view

  alias Capinde.Payload.ArchiveInfo
  alias PolicrMiniWeb.AdminV2.API.ManifestView

  def render("uploaded.json", %{archive_info: archive_info}) do
    success(render_one(archive_info, __MODULE__, "archive_info.json"))
  end

  def render("archive_info.json", %{provider: nil}), do: nil

  def render("archive_info.json", %{provider: archive_info})
      when is_struct(archive_info, ArchiveInfo) do
    %{
      manifest: render_one(archive_info.manifest, ManifestView, "manifest.json"),
      images_total: archive_info.total_images
    }
  end

  def render("failure.json", %{message: message}) do
    failure(message)
  end
end
