defmodule PolicrMiniWeb.AdminV2.API.ErrorView do
  use PolicrMiniWeb, :admin_v2_view

  def render("error.json", %{message: message}) do
    failure(message)
  end
end
