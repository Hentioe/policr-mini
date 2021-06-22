defmodule PolicrMiniWeb.PageController do
  use PolicrMiniWeb, :controller

  def index(conn, _params) do
    bot_name = Application.get_env(:policr_mini, PolicrMiniBot)[:name]
    bot_first_name = PolicrMiniBot.name()
    bot_username = PolicrMiniBot.username()
    is_third_party = bot_username not in PolicrMiniBot.official_bots()

    global = %{
      bot_username: bot_username,
      bot_first_name: bot_first_name,
      bot_name: bot_name,
      is_third_party: is_third_party
    }

    render(conn, "index.html", global: global)
  end
end
