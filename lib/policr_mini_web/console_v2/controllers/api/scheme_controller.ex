defmodule PolicrMiniWeb.ConsoleV2.API.SchemeController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.DefaultsServer

  def show(conn, _params) do
    # todo: 换成真实群组的方案数据
    scheme = DefaultsServer.get_scheme()

    render(conn, "show.json", scheme: scheme)
  end
end
