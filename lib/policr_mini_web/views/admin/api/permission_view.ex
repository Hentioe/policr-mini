defmodule PolicrMiniWeb.Admin.API.PermissionView do
  @moduledoc """
  渲染后台权限数据。
  """

  use PolicrMiniWeb, :view

  def render("updated.json", %{permission: permission}) do
    permission = render_one(permission, __MODULE__, "permission.json")

    %{
      permission: permission
    }
  end

  def render("withdraw.json", %{ok: ok}) do
    %{ok: ok}
  end

  def render("permission.json", %{permission: permission}) do
    permission
    |> Map.drop([:__meta__, :chat])
    |> Map.put(:user, render_one(permission.user, PolicrMiniWeb.Admin.API.UserView, "user.json"))
    |> Map.from_struct()
  end
end
