defmodule PolicrMiniWeb.AdminV2.API.StatsController do
  use PolicrMiniWeb, :controller

  def index(conn, _params) do
    # todo: 接入真实数据
    stats = %{
      verification: %{
        total: 100,
        approved: 80,
        rejected: 20
      }
    }

    render(conn, "index.json", stats: stats)
  end
end
