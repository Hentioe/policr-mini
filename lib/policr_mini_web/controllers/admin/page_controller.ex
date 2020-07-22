defmodule PolicrMiniWeb.Admin.PageController do
  use PolicrMiniWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
