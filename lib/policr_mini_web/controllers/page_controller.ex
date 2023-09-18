defmodule PolicrMiniWeb.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMiniWeb.TgAssetsCacher

  def index(conn, _params) do
    bot_name = Application.get_env(:policr_mini, PolicrMiniBot)[:name]
    bot_first_name = PolicrMiniBot.name()
    bot_username = PolicrMiniBot.username()
    is_third_party = bot_username not in PolicrMiniBot.official_bots()
    is_independent = PolicrMiniBot.opt_exist?("--independent")

    global = %{
      bot_username: bot_username,
      bot_first_name: bot_first_name,
      bot_name: bot_name,
      is_third_party: is_third_party,
      is_independent: is_independent
    }

    render(conn, "index.html", global: global)
  end

  @fallback_avatar "/images/avatar-100x100.jpg"

  def own_photo(conn, _params) do
    photo_path =
      TgAssetsCacher.get_photo_asset(PolicrMiniBot.photo_file_id(), fallback: @fallback_avatar)

    Phoenix.Controller.redirect(conn, to: photo_path)
  end

  def uploaded(conn, %{"name" => name} = _params) do
    file_path = Path.join(PolicrMiniWeb.uploaded_path(), name)

    if File.exists?(file_path) do
      content_type = MIME.from_path(file_path)
      file = File.read!(file_path)

      conn
      |> put_resp_content_type(content_type)
      |> send_resp(200, file)
    else
      resp(conn, 404, "Not Found")
    end
  end
end
