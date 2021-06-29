defmodule PolicrMiniWeb.PageController do
  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

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

  @fallback_avatar "/images/avatar-100x100.jpg"

  def own_photo(conn, _params) do
    photo_path = get_photo_assets(PolicrMiniBot.photo_file_id(), fallback_photo: @fallback_avatar)

    Phoenix.Controller.redirect(conn, to: photo_path)
  end
end
