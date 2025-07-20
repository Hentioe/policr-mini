defmodule PolicrMiniWeb.AdminV2.API.PageView do
  use PolicrMiniWeb, :admin_v2_view

  alias Capinde.Payload.{DeployedInfo, ArchiveInfo}
  alias PolicrMiniWeb.AdminV2.API.ManifestView

  def render("assets.json", %{deployed: deployed, uploaded: uploaded}) do
    success(%{
      deployed: render_deployed_info(deployed),
      uploaded: render_archive_info(uploaded)
    })
  end

  defp render_deployed_info(nil), do: nil

  defp render_deployed_info(deployed) when is_struct(deployed, DeployedInfo) do
    %{
      manifest: render_one(deployed.manifest, ManifestView, "manifest.json"),
      images_total: deployed.total_images
    }
  end

  defp render_archive_info(nil), do: nil

  defp render_archive_info(uploaded) when is_struct(uploaded, ArchiveInfo) do
    %{
      manifest: render_one(uploaded.manifest, ManifestView, "manifest.json"),
      images_total: uploaded.total_images
    }
  end
end
