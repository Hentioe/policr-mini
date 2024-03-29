defmodule PolicrMiniWeb.Console.PageController do
  use PolicrMiniWeb, :controller

  def index(conn, _params) do
    # TODO: 加上登录用户信息
    # owner_id = Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id]
    # %{is_third_party: is_third_party, name: name} = PolicrMiniBot.info()

    full_name = "测试用户"
    name = "测试机器人"

    global = %{
      user_info: %{is_owner: true, full_name: full_name},
      bot_info: %{is_third_party: true, name: name}
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
