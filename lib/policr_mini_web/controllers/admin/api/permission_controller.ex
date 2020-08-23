defmodule PolicrMiniWeb.Admin.API.PermissionController do
  @moduledoc """
  和权限相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{PermissionBusiness}

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.API.FallbackController

  def change_readable(conn, %{"id" => id, "value" => value} = _params) do
    with {:ok, permission} <- PermissionBusiness.get(id, preload: [:user]),
         {:ok, _} <- check_permissions(conn, permission.chat_id, [:writable, :owner]),
         {:ok, _} <- safely_check(conn, permission),
         {:ok, permission} <- PermissionBusiness.update(permission, %{readable: value}) do
      render(conn, "updated.json", %{permission: permission})
    end
  end

  def change_writable(conn, %{"id" => id, "value" => value} = _params) do
    with {:ok, permission} <- PermissionBusiness.get(id, preload: [:user]),
         {:ok, _} <- check_permissions(conn, permission.chat_id, [:writable, :owner]),
         {:ok, _} <- safely_check(conn, permission),
         {:ok, permission} <- PermissionBusiness.update(permission, %{writable: value}) do
      render(conn, "updated.json", %{permission: permission})
    end
  end

  def change_customized(conn, %{"id" => id, "value" => value} = _params) do
    with {:ok, permission} <- PermissionBusiness.get(id, preload: [:user]),
         {:ok, _} <- check_permissions(conn, permission.chat_id, [:writable, :owner]),
         {:ok, _} <- safely_check(conn, permission),
         {:ok, permission} <- PermissionBusiness.update(permission, %{customized: value}) do
      render(conn, "updated.json", %{permission: permission})
    end
  end

  @spec safely_check(Plug.Conn.t(), PolicrMini.Schemas.Permission.t()) ::
          {:error, map} | {:ok, []}
  def safely_check(conn, permission) do
    %{assigns: %{user: %{id: user_id}}} = conn

    if user_id == permission.user.id do
      {:error, %{description: "cannot change own permissions"}}
    else
      {:ok, []}
    end
  end
end
