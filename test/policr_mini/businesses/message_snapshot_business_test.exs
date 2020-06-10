defmodule PolicrMini.MessageSnapshotBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{MessageSnapshotBusiness, ChatBusiness}

  def build_params(attrs \\ []) do
    chat_id =
      if chat_id = attrs[:chat_id] do
        chat_id
      else
        {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())
        chat.id
      end

    message_snapshot = Factory.build(:message_snapshot, chat_id: chat_id)
    message_snapshot |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    message_snapshot_params = build_params()
    {:ok, message_snapshot} = MessageSnapshotBusiness.create(message_snapshot_params)

    assert message_snapshot.chat_id == message_snapshot_params.chat_id
    assert message_snapshot.message_id == message_snapshot_params.message_id
    assert message_snapshot.from_user_id == message_snapshot_params.from_user_id
    assert message_snapshot.from_user_name == message_snapshot_params.from_user_name
    assert message_snapshot.date == message_snapshot_params.date
    assert message_snapshot.text == message_snapshot_params.text
    assert message_snapshot.photo_id == message_snapshot_params.photo_id
    assert message_snapshot.caption == message_snapshot_params.caption
    assert message_snapshot.markup_body == message_snapshot_params.markup_body
  end

  test "update/2" do
    message_snapshot_params = build_params()
    {:ok, message_snapshot1} = MessageSnapshotBusiness.create(message_snapshot_params)

    updated_message_id = 198_765
    updated_from_user_id = 1_098_765_432
    updated_from_user_name = "小新"
    updated_date = 1_591_745_779
    updated_text = "我是正文。"
    updated_photo_id = "w5SgESAmpT"
    updated_caption = "请选择图片中的事物类型"
    updated_markup_body = "[回答1](101:1) [回答2](101:2)"

    {:ok, message_snapshot2} =
      message_snapshot1
      |> MessageSnapshotBusiness.update(%{
        message_id: updated_message_id,
        from_user_id: updated_from_user_id,
        from_user_name: updated_from_user_name,
        date: updated_date,
        test: updated_text,
        photo_id: updated_photo_id,
        caption: updated_caption,
        markup_body: updated_markup_body
      })

    assert message_snapshot2.id == message_snapshot1.id
    assert message_snapshot2.message_id == updated_message_id
    assert message_snapshot2.from_user_id == updated_from_user_id
    assert message_snapshot2.from_user_name == updated_from_user_name
    assert message_snapshot2.date == updated_date
    assert message_snapshot2.photo_id == updated_photo_id
    assert message_snapshot2.caption == updated_caption
    assert message_snapshot2.markup_body == updated_markup_body
  end
end
