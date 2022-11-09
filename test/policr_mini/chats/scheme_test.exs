defmodule PolicrMini.Chats.SchemeTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Chats.Scheme

  describe "schema" do
    test "schema metadata" do
      assert Scheme.__schema__(:source) == "schemes"

      assert Scheme.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :verification_mode,
                 :seconds,
                 :timeout_killing_method,
                 :wrong_killing_method,
                 :mention_text,
                 :image_answers_count,
                 :service_message_cleanup,
                 :delay_unban_secs,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Scheme.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    scheme = Factory.build(:scheme, chat_id: 123_456_789_011)

    updated_verification_mode = 1
    updated_seconds = 120
    updated_wrong_killing_method = :kick
    updated_image_answers_count = 5
    updated_delay_unban_secs = 120

    params = %{
      "verification_mode" => updated_verification_mode,
      "seconds" => updated_seconds,
      "wrong_killing_method" => updated_wrong_killing_method,
      "image_answers_count" => updated_image_answers_count,
      "delay_unban_secs" => updated_delay_unban_secs
    }

    changes = %{
      verification_mode: :custom,
      seconds: updated_seconds,
      wrong_killing_method: :kick,
      image_answers_count: updated_image_answers_count,
      delay_unban_secs: updated_delay_unban_secs
    }

    changeset = Scheme.changeset(scheme, params)
    assert changeset.params == params
    assert changeset.data == scheme
    assert changeset.changes == changes

    assert changeset.validations == [
             {:delay_unban_secs,
              {:number, [greater_than_or_equal_to: 45, less_than_or_equal_to: 18000]}},
             {:image_answers_count,
              {:number, [greater_than_or_equal_to: 3, less_than_or_equal_to: 5]}}
           ]

    assert changeset.required == [
             :chat_id
           ]

    assert changeset.valid?
  end
end
