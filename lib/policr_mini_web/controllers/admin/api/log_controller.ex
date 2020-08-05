defmodule PolicrMiniWeb.Admin.API.LogController do
  @moduledoc """
  和持久化存储的日志相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.Logger

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.API.FallbackController

  @default_time_range "1d"
  @hour 3600
  @day @hour * 24
  @week @day * 7

  def index(conn, params) do
    time_range = Map.get(params, "timeRange") || @default_time_range

    level =
      try do
        params |> Map.get("level", "nil") |> String.to_existing_atom()
      rescue
        _ -> nil
      end

    seconds =
      case time_range do
        "1h" ->
          1 * @hour

        "6h" ->
          6 * @hour

        "1d" ->
          1 * @day

        "1w" ->
          1 * @week

        "2w" ->
          2 * @week

        _ ->
          1 * @day
      end

    time_now = DateTime.utc_now()
    beginning = DateTime.add(time_now, -1 * seconds, :second) |> DateTime.to_unix()

    with {:ok, _} <- check_sys_permissions(conn) do
      with {:ok, logs} <- Logger.query(beginning: beginning, level: level) do
        render(conn, "index.json", %{logs: logs, level: level, beginning: beginning, ending: nil})
      end
    end
  end
end
