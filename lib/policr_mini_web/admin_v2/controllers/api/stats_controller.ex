defmodule PolicrMiniWeb.AdminV2.API.StatsController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.{Stats, Chats}

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  @query_schema %{
    range: [type: :string, in: ~w(today 7d 30d all), default: "today"]
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
        [start: "-1d", every: "2h"]

      "7d" ->
        [start: "-7d", every: "1d"]

      "30d" ->
        [start: "-30d", every: "4d"]

      "all" ->
        every = "1y"

        case Chats.first_verification_inserted_at() do
          nil ->
            # 没有验证记录，返回最近一年
            [start: "-1y", every: every]

          start_dt ->
            # 计算 `start_dt` 距现在的天数
            days = DateTime.diff(DateTime.utc_now(), start_dt, :day)
            start = "-#{days}d"

            [start: start, every: every]
        end
    end
  end
end
