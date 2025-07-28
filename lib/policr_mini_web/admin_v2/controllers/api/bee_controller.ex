defmodule PolicrMiniWeb.AdminV2.API.BeeController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Stats

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def reset_stats(conn, _params) do
    run = &Stats.reset_all_stats/0

    with {:ok, bee} <- Honeycomb.gather_honey(:background, "reset_all_stats", run) do
      render(conn, "show.json", bee: bee)
    end
  end
end
