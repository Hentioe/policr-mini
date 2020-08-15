defmodule PolicrMiniWeb.API.IndexView do
  @moduledoc """
  首页数据的渲染实现。
  """

  @doc """
  渲染数据为 JSON。
  """
  @spec render(String.t(), map()) :: map()
  def render("index.json", %{totals: totals}) do
    %{
      totals: totals
    }
  end
end
