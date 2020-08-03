defmodule PolicrMiniWeb.Admin.PageController do
  use PolicrMiniWeb, :controller

  def index(%{assigns: %{user: user}} = conn, _params) do
    owner_id = Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id]

    global = %{is_owner: owner_id == user.id}

    render(conn, "index.html", global: global)
  end
end
