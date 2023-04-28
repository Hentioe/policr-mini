defmodule PolicrMini.Chats.OperationTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Chats.Operation

  describe "schema" do
    test "schema metadata" do
      assert Operation.__schema__(:source) == "operations"

      assert Operation.__schema__(:fields) ==
               [
                 :id,
                 :verification_id,
                 :action,
                 :role,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Operation.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    operation = Factory.build(:operation, verification_id: 1001)

    updated_action = :ban
    updated_role = :admin

    params = %{
      "action" => updated_action,
      "role" => updated_role
    }

    changes = %{
      action: updated_action,
      role: updated_role
    }

    changeset = Operation.changeset(operation, params)
    assert changeset.params == params
    assert changeset.data == operation
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :verification_id,
             :action,
             :role
           ]

    assert changeset.valid?
  end
end
