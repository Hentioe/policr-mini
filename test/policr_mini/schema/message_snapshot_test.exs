defmodule PolicrMini.Schema.MessageSnapshotTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.MessageSnapshot

  describe "schema" do
    test "schema metadata" do
      assert MessageSnapshot.__schema__(:source) == "message_snapshots"

      assert MessageSnapshot.__schema__(:fields) ==
               [
                 :id,
                 :chat_id,
                 :message_id,
                 :from_user_id,
                 :from_user_name,
                 :date,
                 :text,
                 :photo_id,
                 :caption,
                 :markup_body,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert MessageSnapshot.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    message_snapshot = Factory.build(:message_snapshot, chat_id: 123_456_789_011)

    updated_message_id = 19867
    updated_from_user_id = 987_654_321
    updated_from_user_name = "小明"
    updated_date = 1_591_654_974
    updated_photo_id = "DoLdIkjJDx"
    updated_caption = "请回答问题「图片中的事物是？」。您有 20 秒的时间通过此验证，超时将从群组【Elixir 中文交流】中封禁。"
    updated_markup_body = "[老鹰](12345:1) [小鸡](12345:2)"

    params = %{
      "message_id" => updated_message_id,
      "from_user_id" => updated_from_user_id,
      "from_user_name" => updated_from_user_name,
      "date" => updated_date,
      "photo_id" => updated_photo_id,
      "caption" => updated_caption,
      "markup_body" => updated_markup_body
    }

    changes = %{
      message_id: updated_message_id,
      from_user_id: updated_from_user_id,
      from_user_name: updated_from_user_name,
      date: updated_date,
      photo_id: updated_photo_id,
      caption: updated_caption,
      markup_body: updated_markup_body
    }

    changeset = MessageSnapshot.changeset(message_snapshot, params)
    assert changeset.params == params
    assert changeset.data == message_snapshot
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :chat_id,
             :message_id,
             :from_user_id,
             :from_user_name,
             :date
           ]

    assert changeset.valid?
  end
end
