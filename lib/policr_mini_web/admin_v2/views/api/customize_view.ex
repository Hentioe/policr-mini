defmodule PolicrMiniWeb.AdminV2.API.CustomizeView do
  use PolicrMiniWeb, :admin_v2_view

  def render("index.json", %{scheme: scheme}) do
    scheme = render_one(scheme, PolicrMiniWeb.AdminV2.API.SchemeView, "scheme.json")

    success(%{
      scheme: scheme
    })
  end
end
