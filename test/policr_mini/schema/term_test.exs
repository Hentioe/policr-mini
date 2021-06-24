defmodule PolicrMini.Schema.TermTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.Term

  describe "schema" do
    test "schema metadata" do
      assert Term.__schema__(:source) == "terms"

      assert Term.__schema__(:fields) ==
               [
                 :id,
                 :content,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Term.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    term = Factory.build(:term)

    updated_content = "更新后的服务条款。"

    params = %{
      "content" => updated_content
    }

    changes = %{
      content: updated_content
    }

    changeset = Term.changeset(term, params)
    assert changeset.params == params
    assert changeset.data == term
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :id
           ]

    assert changeset.valid?
  end
end
