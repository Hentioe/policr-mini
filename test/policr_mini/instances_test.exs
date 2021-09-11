defmodule PolicrMini.InstancesTest do
  use PolicrMini.DataCase
  doctest PolicrMini.Instances

  alias PolicrMini.{Factory, ChatBusiness, PermissionBusiness, UserBusiness}

  import PolicrMini.Instances

  describe "terms" do
    def build_term_params(attrs \\ []) do
      term = Factory.build(:term)

      term
      |> struct(attrs)
      |> Map.from_struct()
    end

    def build_chat_params(attrs \\ []) do
      chat = Factory.build(:chat)
      chat |> struct(attrs) |> Map.from_struct()
    end

    test "fetch_term/0" do
      {:ok, term} = fetch_term()

      assert term.id == 1
    end

    test "create_term/1" do
      params = build_term_params()
      {:ok, term} = create_term(params)

      assert term.id == params.id
      assert term.content == params.content
    end

    test "update_term/2" do
      params = build_term_params()
      {:ok, term1} = create_term(params)

      updated_content = "更新后的服务条款。"

      params = %{
        "content" => updated_content
      }

      {:ok, term2} = update_term(term1, params)

      assert term2.content == updated_content
    end
  end

  describe "chats" do
    test "create_chat/1" do
      chat_params = build_chat_params()
      {:ok, chat} = create_chat(chat_params)

      assert chat.id == chat_params.id
      assert chat.type == String.to_atom(chat_params.type)
      assert chat.small_photo_id == chat_params.small_photo_id
      assert chat.big_photo_id == chat_params.big_photo_id
      assert chat.username == chat_params.username
      assert chat.description == chat_params.description
      assert chat.invite_link == chat_params.invite_link
      assert chat.is_take_over == chat_params.is_take_over
    end

    test "create_chat/2" do
      chat_params = build_chat_params()
      {:ok, chat1} = create_chat(chat_params)

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

      {:ok, chat2} = update_chat(chat1, params)

      assert chat2.type == String.to_atom(updated_type)
      assert chat2.title == updated_title
      assert chat2.username == updated_username
      assert chat2.description == updated_description
      assert chat2.invite_link == updated_invite_link
    end

    test "fetch_and_update_chat/2" do
      chat_params = build_chat_params()
      {:ok, chat} = fetch_and_update_chat(987_654_321, chat_params)

      assert chat.id == 987_654_321
      assert chat.type == String.to_atom(chat_params.type)
      assert chat.small_photo_id == chat_params.small_photo_id
      assert chat.big_photo_id == chat_params.big_photo_id
      assert chat.username == chat_params.username
      assert chat.description == chat_params.description
      assert chat.invite_link == chat_params.invite_link
      assert chat.is_take_over == chat_params.is_take_over
    end

    test "fetch_and_update_chat/2 with existing data" do
      {:ok, chat1} = create_chat(build_chat_params())
      updated_title = "新 Elixir 交流群"
      {:ok, chat2} = fetch_and_update_chat(chat1.id, build_chat_params(title: updated_title))

      assert chat2.title == updated_title
    end

    test "cancel_chat_takeover/1" do
      {:ok, chat1} = create_chat(build_chat_params())
      assert chat1.is_take_over

      {:ok, chat2} = chat1 |> cancel_chat_takeover()
      assert chat2.is_take_over == false
      assert struct(chat2, is_take_over: true) == chat1
    end

    test "reset_chat_permissions!/2" do
      chat_params = build_chat_params()
      {:ok, chat} = create_chat(chat_params)
      {:ok, user1} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

      reset_chat_permissions!(chat, [
        Factory.build(:permission, user_id: user1.id)
      ])

      users = ChatBusiness.find_administrators(chat.id)
      assert length(users) == 1
      assert hd(users) == user1

      {:ok, user2} = UserBusiness.create(Factory.build(:user, id: 1_988_756) |> Map.from_struct())

      {:ok, _} =
        reset_chat_permissions!(chat, [
          Factory.build(:permission, user_id: user1.id, tg_is_owner: false),
          Factory.build(:permission, user_id: user2.id)
        ])

      users = ChatBusiness.find_administrators(chat.id)
      assert length(users) == 2
      assert hd(users) == user1
      permission = PermissionBusiness.find(chat.id, user1.id)
      assert permission.tg_is_owner == false

      {:ok, _} = chat |> reset_chat_permissions!([])
      users = ChatBusiness.find_administrators(chat.id)
      assert Enum.empty?(users)
    end
  end
end
