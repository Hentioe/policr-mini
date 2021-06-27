defmodule PolicrMini.SponsorshipHistoryBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.SponsorshipHistoryBusiness

  def build_params(attrs \\ []) do
    sponsorship_history = Factory.build(:sponsorship_history)

    sponsorship_history
    |> struct(attrs)
    |> Map.from_struct()
  end

  test "create/1" do
    sponsorship_history_params = build_params()
    {:ok, sponsorship_history} = SponsorshipHistoryBusiness.create(sponsorship_history_params)

    assert sponsorship_history.expected_to == sponsorship_history_params.expected_to
    assert sponsorship_history.amount == sponsorship_history_params.amount
    assert sponsorship_history.has_reached == sponsorship_history_params.has_reached
    assert sponsorship_history.reached_at == sponsorship_history_params.reached_at
  end

  test "update/2" do
    sponsorship_history_params = build_params()
    {:ok, sponsorship_history1} = SponsorshipHistoryBusiness.create(sponsorship_history_params)

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

    {:ok, sponsorship_history2} = SponsorshipHistoryBusiness.update(sponsorship_history1, params)

    assert sponsorship_history2.expected_to == updated_expected_to
    assert sponsorship_history2.amount == updated_amount
    assert sponsorship_history2.has_reached == updated_has_reached
    assert sponsorship_history2.reached_at == updated_reached_at
  end

  test "delete/1" do
    {:ok, _} = SponsorshipHistoryBusiness.create(build_params())
    {:ok, sponsorship_history2} = SponsorshipHistoryBusiness.create(build_params())

    sponsorship_historyship_histories = SponsorshipHistoryBusiness.find_list()

    assert length(sponsorship_historyship_histories) == 2

    {:ok, _} = SponsorshipHistoryBusiness.delete(sponsorship_history2)

    sponsorship_historyship_histories = SponsorshipHistoryBusiness.find_list()

    assert length(sponsorship_historyship_histories) == 1
  end

  test "reached/1" do
    {:ok, sponsorship_history} =
      SponsorshipHistoryBusiness.create(build_params(has_reached: false))

    {:ok, sponsorship_history2} = SponsorshipHistoryBusiness.reached(sponsorship_history)

    assert sponsorship_history2.has_reached == true
  end

  test "find_list/1" do
    {:ok, sponsorship_history1} =
      SponsorshipHistoryBusiness.create(build_params(has_reached: true))

    reached_at = DateTime.add(DateTime.utc_now(), 1, :second)

    {:ok, sponsorship_history2} =
      SponsorshipHistoryBusiness.create(build_params(reached_at: reached_at))

    [sponsorship_history3, sponsorship_history4] = SponsorshipHistoryBusiness.find_list()

    assert sponsorship_history3 == sponsorship_history2
    assert sponsorship_history4 == sponsorship_history1

    [sponsorship_history5] = SponsorshipHistoryBusiness.find_list(has_reached: true)

    assert sponsorship_history1 == sponsorship_history5
  end
end
