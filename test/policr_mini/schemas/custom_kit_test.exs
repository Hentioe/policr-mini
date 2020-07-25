defmodule PolicrMini.Schemas.CustomKitTest do
  use ExUnit.Case
  doctest PolicrMini.Schemas.CustomKit

  alias PolicrMini.Factory
  alias PolicrMini.Schemas.CustomKit

  describe "schema" do
    test "schema metadata" do
      assert CustomKit.__schema__(:source) == "custom_kits"

      assert CustomKit.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :title,
                 :answers,
                 :photos,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert CustomKit.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    custom_kit = Factory.build(:custom_kit, chat_id: 123_456_789_011)

    updated_title = "1 + 1= ?"
    updated_answers = ["+2", "-3"]

    params = %{
      "title" => updated_title,
      "answers" => updated_answers
    }

    changes = %{
      title: updated_title,
      answers: updated_answers
    }

    changeset = CustomKit.changeset(custom_kit, params)
    assert changeset.params == params
    assert changeset.data == custom_kit
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id,
             :title,
             :answers
           ]

    assert changeset.valid?
  end
end
