defmodule PolicrMiniWeb.Console.API.StatsController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Stats

  action_fallback PolicrMiniWeb.API.FallbackController

  import PolicrMiniWeb.Helper

  @query_schema %{
    range: [type: :string, in: ~w(1d1d 1d 7d 30d), default: "7d"]
  }

  def query(conn, %{"chat_id" => chat_id} = params) do
    with {:ok, _} <- check_permissions(conn, chat_id, [:readable]),
         {:ok, params} <- Tarams.cast(params, @query_schema),
         {:ok, result} <- Stats.query(chat_id, range_to_opts(params)) do
      render(conn, "result.json", %{result: result})
    end
  end

  defp range_to_opts(%{range: range}) do
    case range do
      "1d1d" -> [start: "-1d", every: "1d"]
      "1d" -> [start: "-1d", every: "3h"]
      "7d" -> [start: "-7d", every: "1d"]
      "30d" -> [start: "-30d", every: "4d"]
    end
  end
end
