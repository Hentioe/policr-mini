defmodule PolicrMiniBot.Helper.CheckRequiredPermissionsTest do
  use ExUnit.Case

  import PolicrMiniBot.Helper.CheckRequiredPermissions

  test "check_takeover_permissions/1" do
    member = %{
      status: "member",
      can_restrict_members: nil,
      can_delete_messages: nil
    }

    assert :nonadm == check_takeover_permissions(member)

    member = %{
      status: "administrator",
      can_restrict_members: true,
      can_delete_messages: true
    }

    assert :ok == check_takeover_permissions(member)

    member = %{
      status: "administrator",
      can_restrict_members: false,
      can_delete_messages: nil
    }

    assert {:missing, [:can_restrict_members, :can_delete_messages]} ==
             check_takeover_permissions(member)
  end
end
