defmodule PolicrMiniWeb.AdminV2.API.TermView do
  use PolicrMiniWeb, :admin_v2_view

  def render("show.json", %{term: term}) do
    success(render_one(term, __MODULE__, "term.json"))
  end

  def render("term.json", %{term: term}) do
    %{
      content: term.content,
      created_at: term.inserted_at,
      updated_at: term.updated_at
    }
  end
end
