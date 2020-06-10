defmodule PolicrMini.Schema.CustomKitTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.CustomKit

  describe "schema" do
    test "schema metadata" do
      assert CustomKit.__schema__(:source) == "custom_kits"

      assert CustomKit.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :title,
                 :answer_body,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert CustomKit.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    custom_kit = Factory.build(:custom_kit, chat_id: 123_456_789_011)

    updated_title = "1+1=?"
    updated_answer_body = "+2 -3"

    params = %{
      "title" => updated_title,
      "answer_body" => updated_answer_body
    }

    changes = %{
      title: updated_title,
      answer_body: updated_answer_body
    }

    changeset = CustomKit.changeset(custom_kit, params)
    assert changeset.params == params
    assert changeset.data == custom_kit
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id,
             :title,
             :answer_body
           ]

    assert changeset.valid?
  end
end
