defmodule PolicrMini.CustomKitBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{CustomKitBusiness, ChatBusiness}

  def build_params(attrs \\ []) do
    chat_id =
      if chat_id = attrs[:chat_id] do
        chat_id
      else
        {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())
        chat.id
      end

    custom_kit = Factory.build(:custom_kit, chat_id: chat_id)
    custom_kit |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    custom_kit_params = build_params()
    {:ok, custom_kit} = CustomKitBusiness.create(custom_kit_params)

    assert custom_kit.chat_id == custom_kit_params.chat_id
    assert custom_kit.title == custom_kit_params.title
    assert custom_kit.answers == custom_kit_params.answers
  end

  test "update/2" do
    custom_kit = build_params()
    {:ok, custom_kit1} = CustomKitBusiness.create(custom_kit)

    updated_title = "老虎吃人吗？"
    updated_answers = ["+吃", "-不吃"]

    {:ok, custom_kit2} =
      custom_kit1
      |> CustomKitBusiness.update(%{
        title: updated_title,
        answers: updated_answers
      })

    assert custom_kit2.id == custom_kit1.id
    assert custom_kit2.title == updated_title
    assert custom_kit2.answers == updated_answers
  end

  test "find_list/1" do
    custom_kit_params = build_params()
    {:ok, _} = CustomKitBusiness.create(custom_kit_params)
    {:ok, _} = CustomKitBusiness.create(custom_kit_params)

    custom_kits = CustomKitBusiness.find_list(custom_kit_params.chat_id)
    assert length(custom_kits) == 2

    {:ok, chat2} =
      ChatBusiness.create(Factory.build(:chat, id: 1_098_765_432) |> Map.from_struct())

    {:ok, _} = CustomKitBusiness.create(custom_kit_params |> Map.put(:chat_id, chat2.id))

    custom_kits = CustomKitBusiness.find_list(custom_kit_params.chat_id)
    assert length(custom_kits) == 2

    custom_kits = CustomKitBusiness.find_list(chat2.id)
    assert length(custom_kits) == 1
  end

  test "delete/1" do
    custom_kit_params = build_params()
    {:ok, custom_kit} = CustomKitBusiness.create(custom_kit_params)

    custom_kits = CustomKitBusiness.find_list(custom_kit_params.chat_id)
    assert length(custom_kits) == 1

    {:ok, _} = custom_kit |> CustomKitBusiness.delete()

    custom_kits = CustomKitBusiness.find_list(custom_kit_params.chat_id)
    assert Enum.empty?(custom_kits)
  end

  test "random_one/1" do
    custom_kit_params = build_params()
    {:ok, custom_kit1} = CustomKitBusiness.create(custom_kit_params)
    {:ok, custom_kit2} = CustomKitBusiness.create(custom_kit_params |> Map.put(:title, "我是其它问题1"))
    {:ok, custom_kit3} = CustomKitBusiness.create(custom_kit_params |> Map.put(:title, "我是其它问题2"))

    custom_kits = [custom_kit1, custom_kit2, custom_kit3]

    assert custom_kits |> Enum.member?(CustomKitBusiness.random_one(custom_kit_params.chat_id))
    assert custom_kits |> Enum.member?(CustomKitBusiness.random_one(custom_kit_params.chat_id))
    assert custom_kits |> Enum.member?(CustomKitBusiness.random_one(custom_kit_params.chat_id))
  end

  test "create/1 and invalid answers field" do
    incorrect_format_answers = ["无效的答案", "-错误答案"]
    missing_corrent_answers = ["-错误答案1", "-错误答案2"]

    custom_kit_params = build_params(answers: incorrect_format_answers)
    {:error, changeset} = CustomKitBusiness.create(custom_kit_params)

    assert changeset.errors == [{:answers, {"incorrect format", []}}]

    custom_kit_params = %{custom_kit_params | answers: missing_corrent_answers}
    {:error, changeset} = CustomKitBusiness.create(custom_kit_params)

    assert changeset.errors == [{:answers, {"missing correct answer", []}}]

    custom_kit_params = %{custom_kit_params | answers: ["+正确答案", "-错误答案"]}
    {:ok, custom_kit} = CustomKitBusiness.create(custom_kit_params)

    {:error, changeset} =
      CustomKitBusiness.update(custom_kit, %{answers: incorrect_format_answers})

    assert changeset.errors == [{:answers, {"incorrect format", []}}]

    {:error, changeset} =
      CustomKitBusiness.update(custom_kit, %{answers: missing_corrent_answers})

    assert changeset.errors == [{:answers, {"missing correct answer", []}}]
  end
end
