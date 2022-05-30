defmodule PolicrMiniWeb.Admin.PageController do
  use PolicrMiniWeb, :controller

  def index(%{assigns: %{user: user}} = conn, _params) do
    owner_id = Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id]

    %{is_third_party: is_third_party, name: name} = PolicrMiniBot.info()

    fullname = PolicrMiniBot.Helper.fullname(user)

    global = %{
      user_info: %{is_owner: owner_id == user.id, fullname: fullname},
      bot_info: %{is_third_party: is_third_party, name: name}
    }

    render(conn, "index.html", global: global)
  end

  def logout(conn, _params) do
    conn
    |> delete_resp_cookie("token", path: PolicrMiniWeb.TokenAuthentication.cookie_path())
    |> Phoenix.Controller.redirect(to: "/login")
    |> halt()
  end
end
