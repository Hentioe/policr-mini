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

    test "find_or_init_scheme/1" do
      scheme_params = build_params()
      {:ok, scheme1} = create_scheme(scheme_params)

      {:ok, scheme2} = find_or_init_scheme(scheme_params.chat_id)
      assert scheme2 == scheme1

      {:ok, chat2} =
        Instances.create_chat(Factory.build(:chat, id: 1_087_654_321) |> Map.from_struct())

      {:ok, scheme3} = find_or_init_scheme(chat2.id)

      assert scheme3.chat_id == chat2.id
    end

    test "default_scheme/0" do
      {:ok, default} = default_scheme()

      assert default.chat_id == 0
      assert default.verification_mode == :grid
      assert default.seconds == 300
      assert default.timeout_killing_method == :kick
      assert default.wrong_killing_method == :kick
      assert default.service_message_cleanup == [:joined]
      assert default.delay_unban_secs == 300
    end
  end

  describe "custom_kits" do
    def build_custom_kit_params(attrs \\ []) do
      chat_id =
        if chat_id = attrs[:chat_id] do
          chat_id
        else
          {:ok, chat} = Instances.create_chat(Factory.build(:chat) |> Map.from_struct())
          chat.id
        end

      custom_kit = Factory.build(:custom_kit, chat_id: chat_id)
      custom_kit |> struct(attrs) |> Map.from_struct()
    end

    test "create_custom_kit/1" do
      custom_kit_params = build_custom_kit_params()
      {:ok, custom_kit} = create_custom_kit(custom_kit_params)

      assert custom_kit.chat_id == custom_kit_params.chat_id
      assert custom_kit.title == custom_kit_params.title
      assert custom_kit.answers == custom_kit_params.answers
    end

    test "update_custom_kit/2" do
      custom_kit = build_custom_kit_params()
      {:ok, custom_kit1} = create_custom_kit(custom_kit)

      updated_title = "老虎吃人吗？"
      updated_answers = ["+吃", "-不吃"]

      {:ok, custom_kit2} =
        update_custom_kit(custom_kit1, %{
          title: updated_title,
          answers: updated_answers
        })

      assert custom_kit2.id == custom_kit1.id
      assert custom_kit2.title == updated_title
      assert custom_kit2.answers == updated_answers
    end

    test "find_custom_kits/1" do
      custom_kit_params = build_custom_kit_params()
      {:ok, _} = create_custom_kit(custom_kit_params)
      {:ok, _} = create_custom_kit(custom_kit_params)

      custom_kits = find_custom_kits(custom_kit_params.chat_id)
      assert length(custom_kits) == 2

      {:ok, chat2} =
        Instances.create_chat(Factory.build(:chat, id: 1_098_765_432) |> Map.from_struct())

      {:ok, _} = create_custom_kit(custom_kit_params |> Map.put(:chat_id, chat2.id))

      custom_kits = find_custom_kits(custom_kit_params.chat_id)
      assert length(custom_kits) == 2

      custom_kits = find_custom_kits(chat2.id)
      assert length(custom_kits) == 1
    end

    test "delete_custom_kit/1" do
      custom_kit_params = build_custom_kit_params()
      {:ok, custom_kit} = create_custom_kit(custom_kit_params)

      custom_kits = find_custom_kits(custom_kit_params.chat_id)
      assert length(custom_kits) == 1

      {:ok, _} = delete_custom_kit(custom_kit)

      custom_kits = find_custom_kits(custom_kit_params.chat_id)
      assert Enum.empty?(custom_kits)
    end

    test "random_custom_kit/1" do
      custom_kit_params = build_custom_kit_params()
      {:ok, custom_kit1} = create_custom_kit(custom_kit_params)
      {:ok, custom_kit2} = create_custom_kit(custom_kit_params |> Map.put(:title, "我是其它问题1"))
      {:ok, custom_kit3} = create_custom_kit(custom_kit_params |> Map.put(:title, "我是其它问题2"))

      custom_kits = [custom_kit1, custom_kit2, custom_kit3]

      assert Enum.member?(custom_kits, random_custom_kit(custom_kit_params.chat_id))
      assert Enum.member?(custom_kits, random_custom_kit(custom_kit_params.chat_id))
      assert Enum.member?(custom_kits, random_custom_kit(custom_kit_params.chat_id))
    end

    test "create_custom_kit/1 and invalid answers field" do
      incorrect_format_answers = ["无效的答案", "-错误答案"]
      missing_corrent_answers = ["-错误答案1", "-错误答案2"]

      custom_kit_params = build_custom_kit_params(answers: incorrect_format_answers)
      {:error, changeset} = create_custom_kit(custom_kit_params)

      assert changeset.errors == [{:answers, {"incorrect format", []}}]

      custom_kit_params = %{custom_kit_params | answers: missing_corrent_answers}
      {:error, changeset} = create_custom_kit(custom_kit_params)

      assert changeset.errors == [{:answers, {"missing correct answer", []}}]

      custom_kit_params = %{custom_kit_params | answers: ["+正确答案", "-错误答案"]}
      {:ok, custom_kit} = create_custom_kit(custom_kit_params)

      {:error, changeset} = update_custom_kit(custom_kit, %{answers: incorrect_format_answers})

      assert changeset.errors == [{:answers, {"incorrect format", []}}]

      {:error, changeset} = update_custom_kit(custom_kit, %{answers: missing_corrent_answers})

      assert changeset.errors == [{:answers, {"missing correct answer", []}}]
    end
  end

  describe "verifications" do
    def build_verification_params(attrs \\ []) do
      chat_id =
        if chat_id = attrs[:chat_id] do
          chat_id
        else
          {:ok, chat} = :chat |> Factory.build() |> Map.from_struct() |> Instances.create_chat()

          chat.id
        end

      verification = Factory.build(:verification, chat_id: chat_id)

      verification |> struct(attrs) |> Map.from_struct()
    end

    test "create_verification/1" do
      verification_params = build_verification_params()

      {:ok, verification} = create_verification(verification_params)

      assert verification.chat_id == verification_params.chat_id
      assert verification.message_id == verification_params.message_id
      assert verification.indices == verification_params.indices
      assert verification.seconds == verification_params.seconds
      assert verification.status == :waiting
      assert verification.chosen == verification_params.chosen
    end

    test "update_verification/2" do
      verification_params = build_verification_params()
      {:ok, verification1} = create_verification(verification_params)

      updated_message_id = 10_987
      updated_indices = [3, 5]
      updated_seconds = 120
      updated_status = 1
      updated_chosen = 3

      {:ok, verification2} =
        update_verification(verification1, %{
          message_id: updated_message_id,
          indices: updated_indices,
          seconds: updated_seconds,
          status: updated_status,
          chosen: updated_chosen
        })

      assert verification2.id == verification1.id
      assert verification2.message_id == updated_message_id
      assert verification2.indices == updated_indices
      assert verification2.seconds == updated_seconds
      assert verification2.status == :passed
      assert verification2.chosen == updated_chosen
    end

    test "increase_verification_send_times/1" do
      verification_params = build_verification_params()
      {:ok, v} = create_verification(verification_params)

      assert v.send_times == 0

      :ok = increase_verification_send_times(v.id)
      :ok = increase_verification_send_times(v.id)
      :ok = increase_verification_send_times(v.id)

      v = Repo.reload(v)

      assert v != nil
      assert v.send_times == 3
    end

    test "find_last_pending_verification/1" do
      verification_params = build_verification_params()

      {:ok, _verification1} =
        verification_params |> Map.put(:message_id, 100) |> create_verification()

      {:ok, verification2} =
        verification_params |> Map.put(:message_id, 9999) |> create_verification()

      {:ok, _verification3} =
        verification_params |> Map.put(:message_id, 101) |> create_verification()

      last = find_last_pending_verification(verification_params.chat_id)

      assert last == verification2
    end

    test "get_pending_verification_count/2" do
      verification_params = build_verification_params()

      {:ok, _} = create_verification(verification_params)
      {:ok, _} = create_verification(verification_params)
      {:ok, _} = create_verification(verification_params)
      {:ok, _} = create_verification(Map.put(verification_params, :status, 1))

      assert get_pending_verification_count(verification_params.chat_id, :joined) == 3
    end

    test "find_verifications_total/0" do
      verification_params = build_verification_params()

      {:ok, _} = create_verification(verification_params)
      {:ok, _} = create_verification(verification_params)
      {:ok, _} = create_verification(verification_params)
      {:ok, _} = create_verification(verification_params)

      assert find_verifications_total() == 4
    end
  end
end
