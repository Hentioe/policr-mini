defmodule PolicrMiniWeb.AdminV2.API.PageView do
  use PolicrMiniWeb, :admin_v2_view

  alias Capinde.Payload.DeployedInfo
  alias PolicrMiniWeb.AdminV2.API.{ManifestView, ProviderView}

  def render("assets.json", %{deployed: deployed, uploaded: uploaded}) do
    success(%{
      deployed: render_deployed_info(deployed),
      uploaded: render_one(uploaded, ProviderView, "archive_info.json")
    })
  end

  defp render_deployed_info(nil), do: nil

  defp render_deployed_info(deployed) when is_struct(deployed, DeployedInfo) do
    %{
      manifest: render_one(deployed.manifest, ManifestView, "manifest.json"),
      images_total: deployed.total_images
    }
  end
end
