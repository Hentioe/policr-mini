defmodule PolicrMini.VerificationBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{VerificationBusiness, MessageSnapshotBusiness, ChatBusiness}

  def build_params(attrs \\ []) do
    chat_id =
      if chat_id = attrs[:chat_id] do
        chat_id
      else
        {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())
        chat.id
      end

    message_snapshot_id =
      if message_snapshot_id = attrs[:message_snapshot_id] do
        message_snapshot_id
      else
        {:ok, message_snapshot} =
          MessageSnapshotBusiness.create(
            Factory.build(:message_snapshot, chat_id: chat_id)
            |> Map.from_struct()
          )

        message_snapshot.id
      end

    verification =
      Factory.build(:verification, chat_id: chat_id, message_snapshot_id: message_snapshot_id)

    verification |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    verification_params = build_params()
    {:ok, verification} = VerificationBusiness.create(verification_params)

    assert verification.chat_id == verification_params.chat_id
    assert verification.message_snapshot_id == verification_params.message_snapshot_id
    assert verification.message_id == verification_params.message_id
    assert verification.indices == verification_params.indices
    assert verification.seconds == verification_params.seconds
    assert verification.status == :waiting
    assert verification.chosen == verification_params.chosen
  end

  test "update/2" do
    verification_params = build_params()
    {:ok, verification1} = VerificationBusiness.create(verification_params)

    updated_message_id = 10987
    updated_indices = [3, 5]
    updated_seconds = 120
    updated_status = 1
    updated_chosen = 3

    {:ok, verification2} =
      verification1
      |> VerificationBusiness.update(%{
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
end
