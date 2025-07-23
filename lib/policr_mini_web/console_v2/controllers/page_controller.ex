defmodule PolicrMiniWeb.ConsoleV2.PageController do
  use PolicrMiniWeb, :controller

  def home(conn, _params) do
    render(conn, "home.html")
  end
end
