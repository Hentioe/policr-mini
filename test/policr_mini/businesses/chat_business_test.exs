defmodule PolicrMini.ChatBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{ChatBusiness, UserBusiness, PermissionBusiness}

  def build_params(attrs \\ []) do
    user = Factory.build(:chat)
    user |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    chat_params = build_params()
    {:ok, chat} = ChatBusiness.create(chat_params)

    assert chat.id == chat_params.id
    assert chat.type == String.to_atom(chat_params.type)
    assert chat.small_photo_id == chat_params.small_photo_id
    assert chat.big_photo_id == chat_params.big_photo_id
    assert chat.username == chat_params.username
    assert chat.description == chat_params.description
    assert chat.invite_link == chat_params.invite_link
    assert chat.is_take_over == chat_params.is_take_over
  end

  test "update/2" do
    chat_params = build_params()
    {:ok, chat1} = ChatBusiness.create(chat_params)

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

    {:ok, chat2} = chat1 |> ChatBusiness.update(params)

    assert chat2.type == String.to_atom(updated_type)
    assert chat2.title == updated_title
    assert chat2.username == updated_username
    assert chat2.description == updated_description
    assert chat2.invite_link == updated_invite_link
  end

  test "fetch/2" do
    chat_params = build_params()
    {:ok, chat} = ChatBusiness.fetch(987_654_321, chat_params)

    assert chat.id == 987_654_321
    assert chat.type == String.to_atom(chat_params.type)
    assert chat.small_photo_id == chat_params.small_photo_id
    assert chat.big_photo_id == chat_params.big_photo_id
    assert chat.username == chat_params.username
    assert chat.description == chat_params.description
    assert chat.invite_link == chat_params.invite_link
    assert chat.is_take_over == chat_params.is_take_over
  end

  test "fetch/2 and existing data" do
    {:ok, chat1} = ChatBusiness.create(build_params())
    updated_title = "新 Elixir 交流群"
    {:ok, chat2} = ChatBusiness.fetch(chat1.id, build_params(title: updated_title))

    assert chat2.title == updated_title
  end

  test "takeover_cancelled/1" do
    {:ok, chat1} = ChatBusiness.create(build_params())
    assert chat1.is_take_over

    {:ok, chat2} = chat1 |> ChatBusiness.takeover_cancelled()
    assert chat2.is_take_over == false
    assert struct(chat2, is_take_over: true) == chat1
  end

  test "reset_administrators/2" do
    chat_params = build_params()
    {:ok, chat} = ChatBusiness.create(chat_params)
    {:ok, user1} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

    chat
    |> ChatBusiness.reset_administrators([
      Factory.build(:permission, user_id: user1.id)
    ])

    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 1
    assert hd(users) == user1

    {:ok, user2} = UserBusiness.create(Factory.build(:user, id: 1_988_756) |> Map.from_struct())

    {:ok, _} =
      chat
      |> ChatBusiness.reset_administrators([
        Factory.build(:permission, user_id: user1.id, tg_is_owner: false),
        Factory.build(:permission, user_id: user2.id)
      ])

    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 2
    assert hd(users) == user1
    permission = PermissionBusiness.find(chat.id, user1.id)
    assert permission.tg_is_owner == false

    {:ok, _} = chat |> ChatBusiness.reset_administrators([])
    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 0
  end

  test "find_list/1" do
    chat_params = build_params()
    {:ok, chat1} = ChatBusiness.create(chat_params)
    {:ok, chat2} = ChatBusiness.create(chat_params |> Map.put(:id, 1_987_654_321))
    {:ok, user} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

    {:ok, _} =
      chat1
      |> ChatBusiness.reset_administrators([
        Factory.build(:permission, user_id: user.id)
      ])

    {:ok, _} =
      chat2
      |> ChatBusiness.reset_administrators([
        Factory.build(:permission, user_id: user.id)
      ])

    chats = ChatBusiness.find_list(user.id)
    assert length(chats) == 2

    {_, _} = PermissionBusiness.delete(chat1.id, user.id)

    chats = ChatBusiness.find_list(user.id)
    assert length(chats) == 1
    assert hd(chats) == chat2
  end

  test "find_administrators/1" do
    chat_params = build_params()
    {:ok, chat} = ChatBusiness.create(chat_params)
    {:ok, user1} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

    chat
    |> ChatBusiness.reset_administrators([
      Factory.build(:permission, user_id: user1.id)
    ])

    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 1
    assert hd(users) == user1

    {:ok, user2} = UserBusiness.create(Factory.build(:user, id: 1_988_756) |> Map.from_struct())

    {:ok, _} =
      chat
      |> ChatBusiness.reset_administrators([
        Factory.build(:permission, user_id: user1.id, tg_is_owner: false),
        Factory.build(:permission, user_id: user2.id)
      ])

    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 2
  end
end
