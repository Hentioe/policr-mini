defmodule PolicrMiniWeb.Console.API.StatsView do
  use PolicrMiniWeb, :view

  def render("result.json", %{result: result}) do
    result
  end
end
