defmodule PolicrMiniWeb.Console.API.StatsController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Stats

  action_fallback PolicrMiniWeb.API.FallbackController

  import PolicrMiniWeb.Helper

  def query(conn, %{"chat_id" => chat_id} = _params) do
    with {:ok, _} <- check_permissions(conn, chat_id, [:readable]),
         {:ok, result} <- Stats.query(chat_id) do
      render(conn, "result.json", %{result: result})
    end
  end
end
