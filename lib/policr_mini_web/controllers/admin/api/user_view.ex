defmodule PolicrMiniWeb.Admin.API.UserView do
  @moduledoc """
  渲染后台用户数据。
  """

  use PolicrMiniWeb, :view

  def render("user.json", %{user: user}) do
    user
    |> Map.drop([:__meta__, :token_ver])
    |> Map.from_struct()
  end
end
