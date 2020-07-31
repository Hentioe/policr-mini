defmodule PolicrMiniWeb.Helper do
  @moduledoc false

  alias PolicrMini.PermissionBusiness

  @doc """
  检查当前连接中的用户是否具备目标群组的可写权限。
  """
  @spec check_permissions(Plug.Conn.t(), integer, [PermissionBusiness.permission()]) ::
          {:ok, [atom]} | {:error, map}
  def check_permissions(
        %Plug.Conn{assigns: %{user: %{id: user_id}}} = _conn,
        chat_id,
        requires \\ []
      ) do
    permissions = PermissionBusiness.has_permissions(chat_id, user_id)
    missings = Enum.filter(requires, fn p -> !Enum.member?(permissions, p) end)

    cond do
      Enum.empty?(permissions) ->
        {:error, %{description: "does not have any permissions"}}

      !Enum.empty?(missings) ->
        {:error, %{description: "required permissions are missing"}}

      true ->
        {:ok, permissions}
    end
  end
end
