defmodule PolicrMiniWeb.API.TermView do
  @moduledoc """
  渲染前台服务条款数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("term.json", %{term: term}) do
    term |> Map.drop([:__meta__]) |> Map.from_struct()
  end

  def render("index.json", %{term: term, html_content: html_content}) do
    term = render_one(term, __MODULE__, "term.json")

    %{term: term, html_content: html_content}
  end
end
