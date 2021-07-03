defmodule PolicrMiniWeb.Admin.API.PermissionController do
  @moduledoc """
  和权限相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.Instances.Chat
  alias PolicrMini.PermissionBusiness
  alias PolicrMiniBot.{RespSyncCmdPlug, SpeedLimiter}

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

  def sync(conn, %{"chat_id" => chat_id}) do
    with {:ok, _} <- check_permissions(conn, chat_id, [:writable, :owner]),
         :ok <- speed_check(conn, chat_id),
         {:ok, chat} <- Chat.get(chat_id),
         {:ok, _} <- RespSyncCmdPlug.synchronize_administrators(chat) do
      render(conn, "sync.json", %{ok: true})
    end
  end

  @spec speed_check(Plug.Conn.t(), integer) :: :ok | {:error, map}
  defp speed_check(conn, chat_id) do
    %{assigns: %{user: %{id: user_id}}} = conn

    speed_limit_key = "admin-sync-#{user_id}-#{chat_id}"

    if SpeedLimiter.get(speed_limit_key) <= 0 do
      SpeedLimiter.put(speed_limit_key, 5)

      :ok
    else
      {:error, %{description: "too fast, please try again later"}}
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
  @spec demote_administrator(PolicrMini.Schema.Permission.t()) :: {:ok, boolean} | {:error, map}
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

  # 在实施具体写入操作前进行一些和用户与权限的检查，此函数将在以下情况中返回错误：
  # - 调用 API 的用户在操作自身的权限。
  @spec safely_check(Plug.Conn.t(), PolicrMini.Schema.Permission.t()) ::
          {:error, map} | {:ok, []}
  defp safely_check(conn, permission) do
    %{assigns: %{user: %{id: user_id}}} = conn

    if user_id == permission.user.id do
      {:error, %{description: "cannot change own permissions"}}
    else
      {:ok, []}
    end
  end
end
