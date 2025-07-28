defmodule PolicrMiniWeb.ConsoleV2.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Schema.User
  alias PolicrMini.Accounts
  alias PolicrMiniWeb.TgAssetsFetcher

  def photo(conn, %{"id" => id} = _params) do
    user_photo(conn, Accounts.get_user(id))
  end

  defp user_photo(conn, nil) do
    Phoenix.Controller.redirect(conn, to: "/images/avatar.webp")
  end

  defp user_photo(conn, %User{photo: "unset"}) do
    Phoenix.Controller.redirect(conn, to: "/images/avatar.webp")
  end

  defp user_photo(conn, %User{photo: <<"http" <> _rest>> = photo}) do
    Phoenix.Controller.redirect(conn, external: photo)
  end

  defp user_photo(conn, %User{photo: <<"id/" <> photo_id>>}) do
    Phoenix.Controller.redirect(conn, to: TgAssetsFetcher.get_photo(photo_id))
  end

  defp user_photo(conn, %User{photo: photo}) do
    Phoenix.Controller.redirect(conn, to: TgAssetsFetcher.get_photo(photo))
  end

  def home(conn, _params) do
    render(conn, "home.html")
  end
end
