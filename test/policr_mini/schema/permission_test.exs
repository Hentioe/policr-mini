defmodule PolicrMini.Schema.PermissionTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.Permission

  describe "schema" do
    test "schema metadata" do
      assert Permission.__schema__(:source) == "permissions"

      assert Permission.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :user_id,
                 :tg_is_owner,
                 :tg_can_promote_members,
                 :tg_can_restrict_members,
                 :readable,
                 :writable,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Permission.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    permission = Factory.build(:permission, chat_id: 123_456_789_011, user_id: 123_456_789)

    updated_tg_is_owner = false
    updated_tg_can_promote_members = false
    updated_tg_can_restrict_members = false
    updated_readable = false
    updated_writable = false

    params = %{
      "tg_is_owner" => updated_tg_is_owner,
      "tg_can_promote_members" => updated_tg_can_promote_members,
      "tg_can_restrict_members" => updated_tg_can_restrict_members,
      "readable" => updated_readable,
      "writable" => updated_writable
    }

    changes = %{
      tg_is_owner: updated_tg_is_owner,
      tg_can_promote_members: updated_tg_can_promote_members,
      tg_can_restrict_members: updated_tg_can_restrict_members,
      readable: updated_readable,
      writable: updated_writable
    }

    changeset = Permission.changeset(permission, params)
    assert changeset.params == params
    assert changeset.data == permission
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id,
             :user_id,
             :tg_is_owner,
             :tg_can_promote_members,
             :tg_can_restrict_members
           ]

    assert changeset.valid?
  end
end
