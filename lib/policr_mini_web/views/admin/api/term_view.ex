defmodule PolicrMiniWeb.Admin.API.TermView do
  @moduledoc """
  渲染后台服务条款数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("term.json", %{term: term}) do
    term |> Map.drop([:__meta__]) |> Map.from_struct()
  end

  def render("index.json", %{term: term}) do
    term = render_one(term, __MODULE__, "term.json")

    %{term: term}
  end

  def render("preview.json", %{html: html}) do
    %{html: html}
  end
end
