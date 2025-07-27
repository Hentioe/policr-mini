defmodule PolicrMiniWeb.ConsoleV2.API.ErrorView do
  use PolicrMiniWeb, :view
  use PolicrMiniWeb.ConsoleV2.Helpers, :view

  def render("error.json", %{message: message}) do
    failure(message)
  end
end
