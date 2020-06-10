defmodule PolicrMini.SchemeBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{SchemeBusiness, ChatBusiness}

  def build_params(attrs \\ []) do
    chat_id =
      if chat_id = attrs[:chat_id] do
        chat_id
      else
        {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())
        chat.id
      end

    scheme = Factory.build(:scheme, chat_id: chat_id)
    scheme |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    scheme_params = build_params()
    {:ok, scheme} = SchemeBusiness.create(scheme_params)

    assert scheme.chat_id == scheme_params.chat_id
    assert scheme.verification_mode == :image
    assert scheme.verification_entrance == :unity
    assert scheme.verification_occasion == :private
    assert scheme.seconds == scheme_params.seconds
    assert scheme.killing_method == :ban
    assert scheme.is_highlighted == scheme_params.is_highlighted
  end

  test "update/2" do
    scheme_params = build_params()
    {:ok, scheme1} = SchemeBusiness.create(scheme_params)

    updated_verification_mode = 1
    updated_verification_entrance = 1
    updated_verification_occasion = 1
    updated_seconds = 120
    updated_killing_method = 1
    updated_is_highlighted = false

    {:ok, scheme2} =
      scheme1
      |> SchemeBusiness.update(%{
        verification_mode: updated_verification_mode,
        verification_entrance: updated_verification_entrance,
        verification_occasion: updated_verification_occasion,
        seconds: updated_seconds,
        killing_method: updated_killing_method,
        is_highlighted: updated_is_highlighted
      })

    assert scheme2.id == scheme1.id
    assert scheme2.verification_mode == :custom
    assert scheme2.verification_entrance == :independent
    assert scheme2.verification_occasion == :public
    assert scheme2.seconds == updated_seconds
    assert scheme2.killing_method == :kick
    assert scheme2.is_highlighted == updated_is_highlighted
  end

  test "find/1" do
    scheme_params = build_params()
    {:ok, scheme1} = SchemeBusiness.create(scheme_params)

    scheme2 = SchemeBusiness.find(scheme_params.chat_id)
    assert scheme2 == scheme1

    assert SchemeBusiness.find(0) == nil
  end

  test "fetch/1" do
    scheme_params = build_params()
    {:ok, scheme1} = SchemeBusiness.create(scheme_params)

    {:ok, scheme2} = SchemeBusiness.fetch(scheme_params.chat_id)
    assert scheme2 == scheme1

    {:ok, chat2} =
      ChatBusiness.create(Factory.build(:chat, id: 1_087_654_321) |> Map.from_struct())

    {:ok, scheme3} = SchemeBusiness.fetch(chat2.id)

    assert scheme3.chat_id == chat2.id
  end
end
