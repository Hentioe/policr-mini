defmodule PolicrMini.Chats.StatisticTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Chats.Statistic

  describe "schema" do
    test "schema metadata" do
      assert Statistic.__schema__(:source) == "statistics"

      assert Statistic.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :verifications_count,
                 :languages_top,
                 :begin_at,
                 :end_at,
                 :verification_status,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Statistic.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    statistic = Factory.build(:statistic, chat_id: 123_456_789_011)

    updated_verifications_count = 1
    updated_languages_top = %{"zh-hans" => 1}
    updated_verification_status = :timeout

    params = %{
      "verifications_count" => updated_verifications_count,
      "languages_top" => updated_languages_top,
      "verification_status" => updated_verification_status
    }

    changes = %{
      verifications_count: updated_verifications_count,
      languages_top: updated_languages_top,
      verification_status: updated_verification_status
    }

    changeset = Statistic.changeset(statistic, params)
    assert changeset.params == params
    assert changeset.data == statistic
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id
           ]

    assert changeset.valid?
  end
end
