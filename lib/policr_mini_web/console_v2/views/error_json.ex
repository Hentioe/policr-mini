defmodule PolicrMiniWeb.ConsoleV2.API.ErrorView do
  use PolicrMiniWeb, :console_v2_view

  def render("error.json", %{message: message}) do
    failure(message)
  end
end
