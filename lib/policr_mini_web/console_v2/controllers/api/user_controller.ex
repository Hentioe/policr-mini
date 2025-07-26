defmodule PolicrMiniWeb.ConsoleV2.API.UserController do
  use PolicrMiniWeb, :controller

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  def me(conn, _params) do
    render(conn, "show.json", user: conn.assigns[:user])
  end
end
