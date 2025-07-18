defmodule PolicrMiniWeb.AdminV2.API.ProfileView do
  use PolicrMiniWeb, :admin_v2_view

  def render("index.json", %{profile: profile}) do
    success(profile)
  end
end
