defmodule PolicrMiniWeb.ConsoleV2.API.UserController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Schema.User

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  def me(conn, _params) do
    # todo: 将此处的 user 换成当前用户
    user = %User{
      id: 1,
      first_name: "小红红",
      last_name: nil,
      photo_id: "123456789"
    }

    render(conn, "show.json", user: user)
  end
end
