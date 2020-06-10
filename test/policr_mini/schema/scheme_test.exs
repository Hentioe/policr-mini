defmodule PolicrMini.Schema.SchemeTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.Scheme

  describe "schema" do
    test "schema metadata" do
      assert Scheme.__schema__(:source) == "schemes"

      assert Scheme.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :verification_mode,
                 :verification_entrance,
                 :verification_occasion,
                 :seconds,
                 :killing_method,
                 :is_highlighted,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Scheme.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    scheme = Factory.build(:scheme, chat_id: 123_456_789_011)

    updated_verification_mode = 1
    updated_verification_entrance = 0
    updated_verification_occasion = 0
    updated_seconds = 120
    updated_killing_method = 1
    updated_is_highlighted = false

    params = %{
      "verification_mode" => updated_verification_mode,
      "verification_entrance" => updated_verification_entrance,
      "verification_occasion" => updated_verification_occasion,
      "seconds" => updated_seconds,
      "killing_method" => updated_killing_method,
      "is_highlighted" => updated_is_highlighted
    }

    changes = %{
      verification_mode: :custom,
      verification_entrance: :unity,
      verification_occasion: :private,
      seconds: updated_seconds,
      killing_method: :kick,
      is_highlighted: updated_is_highlighted
    }

    changeset = Scheme.changeset(scheme, params)
    assert changeset.params == params
    assert changeset.data == scheme
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id
           ]

    assert changeset.valid?
  end
end
