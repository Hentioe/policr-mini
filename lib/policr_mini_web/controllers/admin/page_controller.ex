defmodule PolicrMiniWeb.Admin.PageController do
  use PolicrMiniWeb, :controller

  def index(%{assigns: %{user: user}} = conn, _params) do
    owner_id = Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id]
    bot_username = PolicrMiniBot.username()
    is_third_party = bot_username not in PolicrMiniBot.official_bots()
    name = PolicrMiniBot.name()

    global = %{is_owner: owner_id == user.id, is_third_party: is_third_party, name: name}

    render(conn, "index.html", global: global)
  end
end
