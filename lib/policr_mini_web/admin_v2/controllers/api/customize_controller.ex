defmodule PolicrMiniWeb.AdminV2.API.CustomizeController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.DefaultsServer

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def index(conn, _params) do
    scheme = DefaultsServer.get_scheme()

    render(conn, "index.json", scheme: scheme)
  end
end
