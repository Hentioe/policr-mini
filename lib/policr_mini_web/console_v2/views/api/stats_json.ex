defmodule PolicrMiniWeb.ConsoleV2.API.StatsView do
  use PolicrMiniWeb, :view
  use PolicrMiniWeb.ConsoleV2.Helpers, :view

  alias PolicrMini.Stats.{QueryResult, MinimizedPoint}

  def render("show.json", %{stats: stats}) when is_struct(stats, QueryResult) do
    success(render_one(stats, __MODULE__, "stats.json"))
  end

  def render("stats.json", %{stats: stats}) do
    %{
      start: stats.start,
      every: stats.every,
      points: render_points(stats.points)
    }
  end

  defp render_points(points) when is_list(points) do
    Enum.map(points, &render_point/1)
  end

  defp render_point(point) when is_struct(point, MinimizedPoint) do
    %{
      time: point.time,
      status: point.status,
      count: point.count
    }
  end
end
