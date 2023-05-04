defmodule PolicrMiniBot.Helper.CheckRequiredPermissions do
  @moduledoc false

  @type permission :: :can_restrict_members | :can_delete_messages

  def check_takeover_permissions(%{status: status} = _member)
      when status != "administrator" do
    :nonadm
  end

  def check_takeover_permissions(member) do
    missing_permissions =
      []
      |> check_and_append_missing_permission(member, :can_restrict_members)
      |> check_and_append_missing_permission(member, :can_delete_messages)

    if Enum.empty?(missing_permissions), do: :ok, else: {:missing, missing_permissions}
  end

  defp check_and_append_missing_permission(missing_permissions, member, permission) do
    if Map.get(member, permission) != true do
      missing_permissions ++ [permission]
    else
      missing_permissions
    end
  end
end
