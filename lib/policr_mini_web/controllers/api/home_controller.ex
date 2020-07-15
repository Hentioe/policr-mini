defmodule PolicrMiniWeb.API.HomeController do
  @moduledoc """
  首页 API 控制器实现。
  """
  use PolicrMiniWeb, :controller

  alias PolicrMini.VerificationBusiness

  def index(conn, _params) do
    total = VerificationBusiness.get_total()

    render(conn, "index.json", %{total: total})
  end
end
