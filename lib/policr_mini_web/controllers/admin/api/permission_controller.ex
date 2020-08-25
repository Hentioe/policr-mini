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

  def withdraw(conn, %{"id" => id} = _params) do
    with {:ok, permission} <- PermissionBusiness.get(id, preload: [:user]),
         {:ok, _} <- check_permissions(conn, permission.chat_id, [:writable, :owner]),
         {:ok, _} <- safely_check(conn, permission),
         {:ok, ok} <- demote_administrator(permission),
         {:ok, _} <- PermissionBusiness.delete(permission) do
      render(conn, "withdraw.json", %{ok: ok})
    end
  end

  @demoted_all_permissions [
    can_change_info: false,
    can_post_messages: false,
    can_edit_messages: false,
    can_delete_messages: false,
    can_invite_users: false,
    can_restrict_members: false,
    can_pin_messages: false,
    can_promote_members: false
  ]
  @spec demote_administrator(PolicrMini.Schemas.Permission.t()) :: {:ok, boolean} | {:error, map}
  defp demote_administrator(%{chat_id: chat_id, user_id: user_id} = _permission) do
    case Telegex.promote_chat_member(chat_id, user_id, @demoted_all_permissions) do
      {:ok, true} ->
        {:ok, true}

      {:error, %Telegex.Model.Error{description: <<"Bad Request: " <> reason>>}} ->
        description =
          case reason do
            "not enough rights" -> "bot cannot add new admins"
            "CHAT_ADMIN_REQUIRED" -> "not added by bot"
            _ -> reason
          end

        {:error, %{description: description}}

      {:error, %Telegex.Model.Error{description: description}} ->
        {:error, %{description: description}}

      {:error, %Telegex.Model.RequestError{reason: _reason}} ->
        {:error, %{description: "please try again"}}
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
