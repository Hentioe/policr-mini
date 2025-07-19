defmodule PolicrMiniWeb.AdminV2.API.StatsView do
  use PolicrMiniWeb, :admin_v2_view

  def render("index.json", %{stats: stats}) do
    success(stats)
  end
end
