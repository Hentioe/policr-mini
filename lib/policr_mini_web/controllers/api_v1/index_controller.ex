defmodule PolicrMiniWeb.API.V1.IndexController do
  use PolicrMiniWeb, :controller
  plug CORSPlug, origin: ["*"], credentials: false

  alias PolicrMini.Counter

  def totals(conn, _params) do
    totals = %{
      all: Counter.get(:verification_total),
      approved: Counter.get(:verification_passed_total),
      timed_out: Counter.get(:verification_timeout_total)
    }

    json(conn, totals)
  end
end
