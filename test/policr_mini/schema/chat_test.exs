defmodule PolicrMini.Schema.ChatTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.Chat

  describe "schema" do
    test "schema metadata" do
      assert Chat.__schema__(:source) == "chats"

      assert Chat.__schema__(:fields) ==
               [
                 :id,
                 :type,
                 :title,
                 :small_photo_id,
                 :big_photo_id,
                 :username,
                 :description,
                 :invite_link,
                 :is_take_over,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Chat.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    chat = Factory.build(:chat)

    updated_type = "private"
    updated_title = "标题"
    updated_username = "新 Elixir 交流群"
    updated_description = "elixir_new_chat"
    updated_invite_link = "https://t.me/fIkcDF"

    params = %{
      "type" => updated_type,
      "title" => updated_title,
      "username" => updated_username,
      "description" => updated_description,
      "invite_link" => updated_invite_link
    }

    changes = %{
      type: String.to_atom(updated_type),
      title: updated_title,
      username: updated_username,
      description: updated_description,
      invite_link: updated_invite_link
    }

    changeset = Chat.changeset(chat, params)
    assert changeset.params == params
    assert changeset.data == chat
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :id,
             :type,
             :is_take_over
           ]

    assert changeset.valid?
  end
end
