defmodule PolicrMini.Chats.VerificationTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Chats.Verification

  describe "schema" do
    test "schema metadata" do
      assert Verification.__schema__(:source) == "verifications"

      assert Verification.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :target_user_id,
                 :target_user_name,
                 :target_user_language_code,
                 :message_id,
                 :indices,
                 :seconds,
                 :status,
                 :chosen,
                 :source,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Verification.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    verification = Factory.build(:verification, chat_id: 123_456_789_011)

    updated_message_id = 19_121
    updated_indices = [2, 3]
    updated_seconds = 120
    updated_status = 3
    updated_chosen = 1

    params = %{
      "message_id" => updated_message_id,
      "indices" => updated_indices,
      "seconds" => updated_seconds,
      "status" => updated_status,
      "chosen" => updated_chosen
    }

    changes = %{
      message_id: updated_message_id,
      indices: updated_indices,
      seconds: updated_seconds,
      status: :wronged,
      chosen: updated_chosen
    }

    changeset = Verification.changeset(verification, params)
    assert changeset.params == params
    assert changeset.data == verification
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id,
             :target_user_id,
             :seconds,
             :status,
             :source
           ]

    assert changeset.valid?
  end
end
