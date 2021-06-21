defmodule PolicrMini.StatisticBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{StatisticBusiness, ChatBusiness}

  def build_params(attrs \\ []) do
    chat_id =
      if chat_id = attrs[:chat_id] do
        chat_id
      else
        {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())
        chat.id
      end

    user = Factory.build(:statistic, chat_id: chat_id)

    user
    |> struct(attrs)
    |> Map.put(:chat_id, 1_234_567_890)
    |> Map.from_struct()
  end

  test "create/1" do
    statistic_params = build_params()
    {:ok, statistic} = StatisticBusiness.create(statistic_params)

    assert statistic.verifications_count == statistic_params.verifications_count
    assert statistic.languages_top == statistic_params.languages_top
    assert statistic.begin_at == statistic_params.begin_at
    assert statistic.end_at == statistic_params.end_at
    assert statistic.verification_status == statistic_params.verification_status
  end

  test "update/2" do
    statistic_params = build_params()
    {:ok, statistic1} = StatisticBusiness.create(statistic_params)

    utc_now_dt = DateTime.truncate(DateTime.utc_now(), :second)

    updated_verifications_count = 3
    updated_languages_top = %{"unknown" => 1, "zh-hans" => 2}
    updated_begin_at = utc_now_dt
    updated_end_at = utc_now_dt
    updated_verification_status = :other

    params = %{
      "verifications_count" => updated_verifications_count,
      "languages_top" => updated_languages_top,
      "begin_at" => updated_begin_at,
      "end_at" => updated_end_at,
      "verification_status" => updated_verification_status
    }

    {:ok, statistic2} = statistic1 |> StatisticBusiness.update(params)

    assert statistic2.verifications_count == updated_verifications_count
    assert statistic2.languages_top == updated_languages_top
    assert statistic2.begin_at == updated_begin_at
    assert statistic2.end_at == updated_end_at
    assert statistic2.verification_status == updated_verification_status
  end

  test "find_today/2" do
    statistic_params = build_params()

    {:ok, statistic1} =
      statistic_params
      |> Map.put(:verification_status, :passed)
      |> StatisticBusiness.create()

    {:ok, statistic2} =
      statistic_params
      |> Map.put(:verification_status, :timeout)
      |> StatisticBusiness.create()

    stat_passwed = StatisticBusiness.find_today(statistic1.chat_id, :passed)
    stat_timeout = StatisticBusiness.find_today(statistic1.chat_id, :timeout)

    assert statistic1.id == stat_passwed.id
    assert statistic1.verifications_count == stat_passwed.verifications_count
    assert statistic1.languages_top == stat_passwed.languages_top
    assert statistic1.begin_at == stat_passwed.begin_at
    assert statistic1.end_at == stat_passwed.end_at
    assert statistic1.verification_status == stat_passwed.verification_status

    assert statistic2.id == stat_timeout.id
    assert statistic2.verifications_count == stat_timeout.verifications_count
    assert statistic2.languages_top == stat_timeout.languages_top
    assert statistic2.begin_at == stat_timeout.begin_at
    assert statistic2.end_at == stat_timeout.end_at
    assert statistic2.verification_status == stat_timeout.verification_status
  end

  test "find_yesterday/2" do
    statistic_params = build_params()

    today_date = Date.utc_today()
    yesterday_date = Date.add(today_date, -1)

    begin_at = DateTime.new!(yesterday_date, ~T[00:00:00], "Etc/UTC")
    end_at = DateTime.add(begin_at, 3600 * 24 - 1, :second)

    {:ok, statistic1} =
      statistic_params
      |> Map.put(:verification_status, :passed)
      |> Map.put(:begin_at, begin_at)
      |> Map.put(:end_at, end_at)
      |> StatisticBusiness.create()

    {:ok, statistic2} =
      statistic_params
      |> Map.put(:verification_status, :timeout)
      |> Map.put(:begin_at, begin_at)
      |> Map.put(:end_at, end_at)
      |> StatisticBusiness.create()

    stat_passwed = StatisticBusiness.find_yesterday(statistic1.chat_id, :passed)
    stat_timeout = StatisticBusiness.find_yesterday(statistic1.chat_id, :timeout)

    assert statistic1
    assert statistic1.id == stat_passwed.id
    assert statistic1.verifications_count == stat_passwed.verifications_count
    assert statistic1.languages_top == stat_passwed.languages_top
    assert statistic1.begin_at == stat_passwed.begin_at
    assert statistic1.end_at == stat_passwed.end_at
    assert statistic1.verification_status == stat_passwed.verification_status

    assert statistic2
    assert statistic2.id == stat_timeout.id
    assert statistic2.verifications_count == stat_timeout.verifications_count
    assert statistic2.languages_top == stat_timeout.languages_top
    assert statistic2.begin_at == stat_timeout.begin_at
    assert statistic2.end_at == stat_timeout.end_at
    assert statistic2.verification_status == stat_timeout.verification_status
  end

  test "increment_one/3" do
    {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())

    {:ok, _} = StatisticBusiness.increment_one(chat.id, "zh-hans", :passed)
    {:ok, _} = StatisticBusiness.increment_one(chat.id, "zh-hans", :passed)
    {:ok, _} = StatisticBusiness.increment_one(chat.id, "unknown", :passed)
    # 注意，语言代码值为 `nil` 会被记录为 `unknown`。
    {:ok, statistic1} = StatisticBusiness.increment_one(chat.id, nil, :passed)
    {:ok, statistic2} = StatisticBusiness.increment_one(chat.id, "zh-hans", :timeout)

    assert statistic1.verifications_count == 4
    assert statistic1.languages_top == %{"zh-hans" => 2, "unknown" => 2}
    assert statistic2.verifications_count == 1
    assert statistic2.languages_top == %{"zh-hans" => 1}

    today_begin_at = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
    today_end_at = DateTime.add(today_begin_at, 3600 * 24 - 1, :second)

    assert statistic1.begin_at == today_begin_at
    assert statistic2.begin_at == today_begin_at
    assert statistic1.end_at == today_end_at
    assert statistic2.end_at == today_end_at
  end
end
