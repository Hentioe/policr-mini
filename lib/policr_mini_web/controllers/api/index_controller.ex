defmodule PolicrMiniWeb.API.IndexController do
  @moduledoc """
  首页 API 控制器实现。
  """
  use PolicrMiniWeb, :controller

  alias PolicrMini.Counter

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    total = Counter.get(:verification_total)

    render(conn, "index.json", %{total: total})
  end
end
