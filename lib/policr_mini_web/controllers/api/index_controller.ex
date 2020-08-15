defmodule PolicrMiniWeb.API.IndexController do
  @moduledoc """
  首页 API 的控制器。
  """
  use PolicrMiniWeb, :controller

  alias PolicrMini.Counter

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    totals = %{
      verification_all: Counter.get(:verification_total),
      verification_no_pass: Counter.get(:verification_no_pass_total),
      verification_timeout: Counter.get(:verification_timeout_total)
    }

    render(conn, "index.json", %{totals: totals})
  end
end
