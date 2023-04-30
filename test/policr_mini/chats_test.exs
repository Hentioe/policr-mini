defmodule PolicrMini.ChatsTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.Instances

  import PolicrMini.Chats

  describe "schemes" do
    def build_params(attrs \\ []) do
      chat_id =
        if chat_id = attrs[:chat_id] do
          chat_id
        else
          {:ok, chat} = Instances.create_chat(Map.from_struct(Factory.build(:chat)))

          chat.id
        end

      scheme = Factory.build(:scheme, chat_id: chat_id)
      scheme |> struct(attrs) |> Map.from_struct()
    end

    test "create_scheme/1" do
      scheme_params = build_params()
      {:ok, scheme} = create_scheme(scheme_params)

      assert scheme.chat_id == scheme_params.chat_id
      assert scheme.verification_mode == :image
      assert scheme.seconds == scheme_params.seconds
      assert scheme.wrong_killing_method == :ban
      assert scheme.service_message_cleanup == [:joined]
    end

    test "update_scheme/2" do
      scheme_params = build_params()
      {:ok, scheme1} = create_scheme(scheme_params)

      updated_verification_mode = 1
      updated_seconds = 120
      updated_timeout_killing_method = :ban
      updated_service_message_cleanup = [:joined, :lefted]
      updated_delay_unban_secs = 120

      {:ok, scheme2} =
        update_scheme(scheme1, %{
          verification_mode: updated_verification_mode,
          seconds: updated_seconds,
          timeout_killing_method: updated_timeout_killing_method,
          service_message_cleanup: updated_service_message_cleanup,
          delay_unban_secs: updated_delay_unban_secs
        })

      assert scheme2.id == scheme1.id
      assert scheme2.verification_mode == :custom
      assert scheme2.seconds == updated_seconds
      assert scheme2.timeout_killing_method == :ban
      assert scheme2.service_message_cleanup == updated_service_message_cleanup
      assert scheme2.delay_unban_secs == updated_delay_unban_secs
    end

    test "find_scheme/1" do
      scheme_params = build_params()
      {:ok, scheme1} = create_scheme(scheme_params)

      scheme2 = find_scheme(scheme_params.chat_id)
      assert scheme2 == scheme1

      assert find_scheme(-1) == nil
    end

    test "fetch_scheme/1" do
      scheme_params = build_params()
      {:ok, scheme1} = create_scheme(scheme_params)

      {:ok, scheme2} = fetch_scheme(scheme_params.chat_id)
      assert scheme2 == scheme1

      {:ok, chat2} =
        Instances.create_chat(Factory.build(:chat, id: 1_087_654_321) |> Map.from_struct())

      {:ok, scheme3} = fetch_scheme(chat2.id)

      assert scheme3.chat_id == chat2.id
    end

    test "fetch_default_scheme/0" do
      {:ok, default} = fetch_default_scheme()

      assert default.chat_id == 0
      assert default.verification_mode == :image
      assert default.seconds == 300
      assert default.timeout_killing_method == :kick
      assert default.wrong_killing_method == :kick
      assert default.service_message_cleanup == [:joined]
      assert default.delay_unban_secs == 300
    end
  end

  describe "statistics" do
    def build_statistic_params(attrs \\ []) do
      chat_id =
        if chat_id = attrs[:chat_id] do
          chat_id
        else
          {:ok, chat} = Instances.create_chat(Factory.build(:chat) |> Map.from_struct())
          chat.id
        end

      user = Factory.build(:statistic, chat_id: chat_id)

      user
      |> struct(attrs)
      |> Map.put(:chat_id, 1_234_567_890)
      |> Map.from_struct()
    end

    test "create_statistic/1" do
      statistic_params = build_statistic_params()
      {:ok, statistic} = create_statistic(statistic_params)

      assert statistic.verifications_count == statistic_params.verifications_count
      assert statistic.languages_top == statistic_params.languages_top
      assert statistic.begin_at == statistic_params.begin_at
      assert statistic.end_at == statistic_params.end_at
      assert statistic.verification_status == statistic_params.verification_status
    end

    test "update_statistic/2" do
      statistic_params = build_statistic_params()
      {:ok, s1} = create_statistic(statistic_params)

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

      {:ok, s2} = update_statistic(s1, params)

      assert s2.verifications_count == updated_verifications_count
      assert s2.languages_top == updated_languages_top
      assert s2.begin_at == updated_begin_at
      assert s2.end_at == updated_end_at
      assert s2.verification_status == updated_verification_status
    end

    test "find_today_stat/2" do
      statistic_params = build_statistic_params()

      {:ok, s1} =
        statistic_params
        |> Map.put(:verification_status, :passed)
        |> create_statistic()

      {:ok, s2} =
        statistic_params
        |> Map.put(:verification_status, :timeout)
        |> create_statistic()

      stat_passed = find_today_stat(s1.chat_id, :passed)
      stat_timeout = find_today_stat(s1.chat_id, :timeout)

      assert s1.id == stat_passed.id
      assert s1.verifications_count == stat_passed.verifications_count
      assert s1.languages_top == stat_passed.languages_top
      assert s1.begin_at == stat_passed.begin_at
      assert s1.end_at == stat_passed.end_at
      assert s1.verification_status == stat_passed.verification_status

      assert s2.id == stat_timeout.id
      assert s2.verifications_count == stat_timeout.verifications_count
      assert s2.languages_top == stat_timeout.languages_top
      assert s2.begin_at == stat_timeout.begin_at
      assert s2.end_at == stat_timeout.end_at
      assert s2.verification_status == stat_timeout.verification_status
    end

    test "find_yesterday_stat/2" do
      statistic_params = build_statistic_params()

      today_date = Date.utc_today()
      yesterday_date = Date.add(today_date, -1)

      begin_at = DateTime.new!(yesterday_date, ~T[00:00:00], "Etc/UTC")
      end_at = DateTime.add(begin_at, 3600 * 24 - 1, :second)

      {:ok, s1} =
        statistic_params
        |> Map.put(:verification_status, :passed)
        |> Map.put(:begin_at, begin_at)
        |> Map.put(:end_at, end_at)
        |> create_statistic()

      {:ok, s2} =
        statistic_params
        |> Map.put(:verification_status, :timeout)
        |> Map.put(:begin_at, begin_at)
        |> Map.put(:end_at, end_at)
        |> create_statistic()

      stat_passed = find_yesterday_stat(s1.chat_id, :passed)
      stat_timeout = find_yesterday_stat(s1.chat_id, :timeout)

      assert s1
      assert s1.id == stat_passed.id
      assert s1.verifications_count == stat_passed.verifications_count
      assert s1.languages_top == stat_passed.languages_top
      assert s1.begin_at == stat_passed.begin_at
      assert s1.end_at == stat_passed.end_at
      assert s1.verification_status == stat_passed.verification_status

      assert s2
      assert s2.id == stat_timeout.id
      assert s2.verifications_count == stat_timeout.verifications_count
      assert s2.languages_top == stat_timeout.languages_top
      assert s2.begin_at == stat_timeout.begin_at
      assert s2.end_at == stat_timeout.end_at
      assert s2.verification_status == stat_timeout.verification_status
    end

    test "increment_statistic/3" do
      {:ok, chat} = Instances.create_chat(Factory.build(:chat) |> Map.from_struct())

      {:ok, _} = increment_statistic(chat.id, "zh-hans", :passed)
      {:ok, _} = increment_statistic(chat.id, "zh-hans", :passed)
      {:ok, _} = increment_statistic(chat.id, "unknown", :passed)
      # 注意，语言代码值为 `nil` 会被记录为 `unknown`。
      {:ok, s1} = increment_statistic(chat.id, nil, :passed)
      {:ok, s2} = increment_statistic(chat.id, "zh-hans", :timeout)

      assert s1.verifications_count == 4
      assert s1.languages_top == %{"zh-hans" => 2, "unknown" => 2}
      assert s2.verifications_count == 1
      assert s2.languages_top == %{"zh-hans" => 1}

      today_begin_at = DateTime.new!(Date.utc_today(), ~T[00:00:00], "Etc/UTC")
      today_end_at = DateTime.add(today_begin_at, 3600 * 24 - 1, :second)

      assert s1.begin_at == today_begin_at
      assert s2.begin_at == today_begin_at
      assert s1.end_at == today_end_at
      assert s2.end_at == today_end_at
    end
  end
end
