defmodule PolicrMiniWeb.PageController do
  use PolicrMiniWeb, :controller

  def index(conn, _params) do
    bot_name = Application.get_env(:policr_mini, PolicrMiniBot)[:name]
    bot_first_name = PolicrMiniBot.name()

    global = %{
      bot_username: PolicrMiniBot.username(),
      bot_first_name: bot_first_name,
      bot_name: bot_name
    }

    render(conn, "index.html", global: global)
  end
end
