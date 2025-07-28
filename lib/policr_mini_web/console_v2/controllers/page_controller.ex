defmodule PolicrMiniWeb.ConsoleV2.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Schema.User
  alias PolicrMini.Instances.Chat
  alias PolicrMini.{Accounts, Uses}
  alias PolicrMiniWeb.TgAssetsFetcher

  @photo_schema %{
    id: [type: :integer]
  }

  def photo(conn, params) do
    with {:ok, params} <- Tarams.cast(params, @photo_schema) do
      if params[:id] < 0 do
        chat_photo(conn, Uses.get_chat(params[:id]))
      else
        user_photo(conn, Accounts.get_user(params[:id]))
      end
    end
  end

  defp chat_photo(conn, %Chat{small_photo_id: small_photo_id}) when small_photo_id != nil do
    Phoenix.Controller.redirect(conn, to: TgAssetsFetcher.get_photo(small_photo_id))
  end

  defp chat_photo(conn, _) do
    Phoenix.Controller.redirect(conn, to: "/images/telegram-128x128.webp")
  end

  defp user_photo(conn, nil) do
    Phoenix.Controller.redirect(conn, to: "/images/avatar.webp")
  end

  defp user_photo(conn, %User{photo: photo}) when photo in [nil, "unset"] do
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
