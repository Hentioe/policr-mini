defmodule PolicrMini.ChatBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.{Factory, Instances}
  alias PolicrMini.{ChatBusiness, UserBusiness, PermissionBusiness}

  def build_params(attrs \\ []) do
    user = Factory.build(:chat)
    user |> struct(attrs) |> Map.from_struct()
  end

  test "find_user_chats/1" do
    chat_params = build_params()
    {:ok, chat1} = Instances.create_chat(chat_params)
    {:ok, chat2} = Instances.create_chat(chat_params |> Map.put(:id, 1_987_654_321))
    {:ok, user} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

    {:ok, _} =
      chat1
      |> Instances.reset_chat_permissions!([
        Factory.build(:permission, user_id: user.id)
      ])

    {:ok, _} =
      chat2
      |> Instances.reset_chat_permissions!([
        Factory.build(:permission, user_id: user.id)
      ])

    chats = Instances.find_user_chats(user.id)
    assert length(chats) == 2

    {_, _} = PermissionBusiness.delete(chat1.id, user.id)

    chats = Instances.find_user_chats(user.id)
    assert length(chats) == 1
    assert hd(chats) == chat2
  end

  test "find_administrators/1" do
    chat_params = build_params()
    {:ok, chat} = Instances.create_chat(chat_params)
    {:ok, user1} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

    chat
    |> Instances.reset_chat_permissions!([
      Factory.build(:permission, user_id: user1.id)
    ])

    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 1
    assert hd(users) == user1

    {:ok, user2} = UserBusiness.create(Factory.build(:user, id: 1_988_756) |> Map.from_struct())

    {:ok, _} =
      chat
      |> Instances.reset_chat_permissions!([
        Factory.build(:permission, user_id: user1.id, tg_is_owner: false),
        Factory.build(:permission, user_id: user2.id)
      ])

    users = ChatBusiness.find_administrators(chat.id)
    assert length(users) == 2
  end
end
