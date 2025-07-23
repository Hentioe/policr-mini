defmodule PolicrMiniWeb.Admin.PageController do
  use PolicrMiniWeb, :controller

  def index(%{assigns: %{user: user}} = conn, _params) do
    fullname = PolicrMiniBot.Helper.fullname(user)

    global = %{
      user_info: %{fullname: fullname}
    }

    render(conn, "index.html", global: global)
  end

  def logout(conn, _params) do
    conn
    |> delete_resp_cookie("token", path: "/admin")
    |> Phoenix.Controller.redirect(to: "/login")
    |> halt()
  end
end
