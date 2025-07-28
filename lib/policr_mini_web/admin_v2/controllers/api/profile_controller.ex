defmodule PolicrMiniWeb.AdminV2.API.ProfileController do
  use PolicrMiniWeb, :controller

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def index(conn, _params) do
    render(conn, "index.json", profile: %{username: "admin"})
  end
end
