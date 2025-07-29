defmodule PolicrMiniWeb.AdminV2.API.BeeController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Stats

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  @reset_stats %{
    range: [type: :string, in: ~w(last_30d all), default: "30d"]
  }

  def reset_stats(conn, params) do
    with {:ok, params} <- Tarams.cast(params, @reset_stats),
         {:ok, bee} <- create_bee(params[:range]) do
      render(conn, "show.json", bee: bee)
    end
  end

  defp create_bee(range) do
    run =
      case range do
        "last_30d" -> fn -> Stats.reset_task(30) end
        "all" -> fn -> Stats.reset_task(365 * 99) end
      end

    Honeycomb.gather_honey(:background, "reset_#{range}", run)
  end
end
