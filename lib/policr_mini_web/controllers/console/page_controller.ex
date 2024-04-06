defmodule PolicrMiniWeb.Console.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMiniWeb.TgAssetsFetcher

  def index(%{assigns: %{user: user}} = conn, _params) do
    owner_id = Application.get_env(:policr_mini, PolicrMiniBot)[:owner_id]
    %{is_third_party: is_third_party, name: name} = PolicrMiniBot.info()

    full_name = PolicrMiniBot.Helper.fullname(user)

    global = %{
      user_info: %{is_owner: owner_id == user.id, full_name: full_name},
      bot_info: %{is_third_party: is_third_party, name: name}
    }

    render(conn, "index.html", global: global)
  end

  def photo(%{assigns: %{user: user}} = conn, _params) do
    if user.photo_id == nil || user.photo_id == "unset" do
      Phoenix.Controller.redirect(conn, to: "/images/avatar-100x100.jpg")
    else
      Phoenix.Controller.redirect(conn, to: TgAssetsFetcher.get_photo(user.photo_id))
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_resp_cookie("token", path: "/console")
    |> Phoenix.Controller.redirect(to: "/login")
    |> halt()
  end
end
