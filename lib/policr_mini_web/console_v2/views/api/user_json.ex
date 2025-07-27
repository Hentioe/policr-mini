defmodule PolicrMiniWeb.ConsoleV2.API.UserView do
  use PolicrMiniWeb, :view
  use PolicrMiniWeb.ConsoleV2.Helpers, :view

  alias PolicrMini.Schema.User

  def render("show.json", %{user: user}) when is_struct(user, User) do
    success(render_one(user, __MODULE__, "user.json"))
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      username: user.username,
      full_name: User.full_name(user)
    }
  end
end
