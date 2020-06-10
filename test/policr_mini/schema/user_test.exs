defmodule PolicrMini.Schema.UserTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.User

  describe "schema" do
    test "schema metadata" do
      assert User.__schema__(:source) == "users"

      assert User.__schema__(:fields) ==
               [
                 :id,
                 :first_name,
                 :last_name,
                 :username,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert User.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    user = Factory.build(:user)

    updated_first_name = "新"
    updated_last_name = "一"
    updated_username = "xinyi"

    params = %{
      "first_name" => updated_first_name,
      "last_name" => updated_last_name,
      "username" => updated_username
    }

    changes = %{
      first_name: updated_first_name,
      last_name: updated_last_name,
      username: updated_username
    }

    changeset = User.changeset(user, params)
    assert changeset.params == params
    assert changeset.data == user
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :id
           ]

    assert changeset.valid?
  end
end
