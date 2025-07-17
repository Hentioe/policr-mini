defmodule PolicrMiniWeb.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMiniWeb.TgAssetsFetcher

  @fallback_avatar "/images/avatar-100x100.jpg"

  def own_photo(conn, _params) do
    photo_path =
      TgAssetsFetcher.get_photo(PolicrMiniBot.photo_file_id(), fallback: @fallback_avatar)

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
