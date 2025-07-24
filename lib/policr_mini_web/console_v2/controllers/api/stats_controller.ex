defmodule PolicrMiniWeb.ConsoleV2.API.StatsController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Stats

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  @query_schema %{
    range: [type: :string, in: ~w(today 7d 28d 90d), default: "7d"]
  }

  def query(conn, params) do
    with {:ok, params} <- Tarams.cast(params, @query_schema),
         {:ok, stats} <- Stats.query(range_to_opts(params)) do
      render(conn, "show.json", %{stats: stats})
    end
  end

  defp range_to_opts(%{range: range}) do
    case range do
      "today" ->
        [start: "-1d", every: "4h"]

      "7d" ->
        [start: "-7d", every: "1d"]

      "28d" ->
        [start: "-28d", every: "4d"]

      "90d" ->
        [start: "-90d", every: "30d"]
    end
  end
end
