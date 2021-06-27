defmodule PolicrMini.Schema.SponsorshipHistoryTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.SponsorshipHistory

  describe "schema" do
    test "schema metadata" do
      assert SponsorshipHistory.__schema__(:source) == "sponsorship_histories"

      assert SponsorshipHistory.__schema__(:fields) ==
               [
                 :id,
                 :sponsor_id,
                 :expected_to,
                 :amount,
                 :has_reached,
                 :reached_at,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert SponsorshipHistory.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    sponsor_history = Factory.build(:sponsorship_history)

    now_dt = DateTime.truncate(DateTime.utc_now(), :second)

    updated_expected_to = "替作者买单一份外卖"
    updated_amount = 35
    updated_has_reached = true
    updated_reached_at = now_dt

    params = %{
      "expected_to" => updated_expected_to,
      "amount" => updated_amount,
      "has_reached" => updated_has_reached,
      "reached_at" => updated_reached_at
    }

    changes = %{
      expected_to: updated_expected_to,
      amount: updated_amount,
      has_reached: updated_has_reached,
      reached_at: updated_reached_at
    }

    changeset = SponsorshipHistory.changeset(sponsor_history, params)
    assert changeset.params == params
    assert changeset.data == sponsor_history
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :amount,
             :has_reached
           ]

    assert changeset.valid?
  end
end
