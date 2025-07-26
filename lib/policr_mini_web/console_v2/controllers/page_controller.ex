defmodule PolicrMiniWeb.ConsoleV2.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMiniWeb.TgAssetsFetcher

  def user_photo(%{assigns: %{user: user}} = conn, _params) do
    cond do
      user.photo == nil || user.photo == "unset" ->
        Phoenix.Controller.redirect(conn, to: "/images/avatar.webp")

      String.starts_with?(user.photo, "http") ->
        Phoenix.Controller.redirect(conn, external: user.photo)

      String.starts_with?(user.photo, "id/") ->
        photo_id = String.slice(user.photo, 3..-1//1)
        Phoenix.Controller.redirect(conn, to: TgAssetsFetcher.get_photo(photo_id))

      true ->
        Phoenix.Controller.redirect(conn, to: TgAssetsFetcher.get_photo(user.photo))
    end
  end

  def home(conn, _params) do
    render(conn, "home.html")
  end
end
