defmodule PolicrMini.PermissionBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.{PermissionBusiness, ChatBusiness, UserBusiness}

  def build_params(attrs \\ []) do
    chat_id =
      if chat_id = attrs[:chat_id] do
        chat_id
      else
        {:ok, chat} = ChatBusiness.create(Factory.build(:chat) |> Map.from_struct())
        chat.id
      end

    user_id =
      if user_id = attrs[:user_id] do
        user_id
      else
        {:ok, user} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())
        user.id
      end

    permission = Factory.build(:permission, chat_id: chat_id, user_id: user_id)
    permission |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    permission_params = build_params()
    {:ok, permission} = PermissionBusiness.create(permission_params)

    assert permission.chat_id == permission_params.chat_id
    assert permission.user_id == permission_params.user_id
    assert permission.tg_is_owner == permission_params.tg_is_owner
    assert permission.tg_can_promote_members == permission_params.tg_can_promote_members
    assert permission.tg_can_restrict_members == permission_params.tg_can_restrict_members
    assert permission.readable == permission_params.readable
    assert permission.writable == permission_params.writable
  end

  test "find/2" do
    permission_params = build_params()
    {:ok, _} = PermissionBusiness.create(permission_params)

    permission = PermissionBusiness.find(permission_params.chat_id, permission_params.user_id)

    assert permission.chat_id == permission_params.chat_id
    assert permission.user_id == permission_params.user_id
    assert permission.tg_is_owner == permission_params.tg_is_owner
    assert permission.tg_can_promote_members == permission_params.tg_can_promote_members
    assert permission.tg_can_restrict_members == permission_params.tg_can_restrict_members
    assert permission.readable == permission_params.readable
    assert permission.writable == permission_params.writable
  end

  test "update/2" do
    permission_params = build_params()
    {:ok, permission1} = PermissionBusiness.create(permission_params)

    updated_tg_is_owner = false
    updated_tg_can_promote_members = false
    updated_tg_can_restrict_members = false
    updated_readable = false
    updated_writable = false

    {:ok, permission2} =
      permission1
      |> PermissionBusiness.update(%{
        tg_is_owner: updated_tg_is_owner,
        tg_can_promote_members: updated_tg_can_promote_members,
        tg_can_restrict_members: updated_tg_can_restrict_members,
        readable: updated_readable,
        writable: updated_writable
      })

    assert permission2.id == permission1.id
    assert permission2.tg_is_owner == updated_tg_is_owner
    assert permission2.tg_can_promote_members == updated_tg_can_promote_members
    assert permission2.tg_can_restrict_members == updated_tg_can_restrict_members
    assert permission2.readable == updated_readable
    assert permission2.writable == updated_writable
  end

  test "fetch/3" do
    permission_params = build_params()

    {:ok, permission} =
      PermissionBusiness.fetch(
        permission_params.chat_id,
        permission_params.user_id,
        permission_params
      )

    assert permission.chat_id == permission_params.chat_id
    assert permission.user_id == permission_params.user_id
    assert permission.tg_is_owner == permission_params.tg_is_owner
    assert permission.tg_can_promote_members == permission_params.tg_can_promote_members
    assert permission.tg_can_restrict_members == permission_params.tg_can_restrict_members
    assert permission.readable == permission_params.readable
    assert permission.writable == permission_params.writable
  end

  test "fetch/3 and existing data" do
    permission_params = build_params()
    {:ok, _} = PermissionBusiness.create(permission_params)
    updated_tg_is_owner = false

    {:ok, permission} =
      PermissionBusiness.fetch(
        permission_params.chat_id,
        permission_params.user_id,
        permission_params |> Map.put(:tg_is_owner, updated_tg_is_owner)
      )

    assert permission.tg_is_owner == updated_tg_is_owner
  end

  test "find_list/1" do
    {:ok, user2} = UserBusiness.create(Factory.build(:user, id: 1_012_345) |> Map.from_struct())
    permission_params = build_params()
    {:ok, _} = PermissionBusiness.create(permission_params |> Map.put(:user_id, user2.id))

    {:ok, chat2} = ChatBusiness.create(Factory.build(:chat, id: 198_765_432) |> Map.from_struct())
    {:ok, chat3} = ChatBusiness.create(Factory.build(:chat, id: 298_765_432) |> Map.from_struct())
    {:ok, user3} = UserBusiness.create(Factory.build(:user, id: 1_912_345) |> Map.from_struct())

    {:ok, _} = PermissionBusiness.create(permission_params |> Map.put(:chat_id, chat2.id))
    {:ok, _} = PermissionBusiness.create(permission_params |> Map.put(:chat_id, chat3.id))

    {:ok, _} =
      PermissionBusiness.create(
        permission_params
        |> Map.put(:user_id, user2.id)
        |> Map.put(:chat_id, chat2.id)
      )

    {:ok, _} = PermissionBusiness.create(permission_params |> Map.put(:user_id, user3.id))

    permissions = PermissionBusiness.find_list([])
    assert length(permissions) == 5

    chat1_permissions = PermissionBusiness.find_list(chat_id: permission_params.chat_id)
    assert length(chat1_permissions) == 2
    user2_permissions = PermissionBusiness.find_list(user_id: user2.id)
    assert length(user2_permissions) == 2

    chat1_user2_permissions =
      PermissionBusiness.find_list(chat_id: permission_params.chat_id, user_id: user2.id)

    assert length(chat1_user2_permissions) == 1
  end

  test "delete/2" do
    permission_params = build_params()
    {:ok, _} = PermissionBusiness.create(permission_params)

    permissions =
      PermissionBusiness.find_list(
        chat_id: permission_params.chat_id,
        user_id: permission_params.user_id
      )

    assert length(permissions) == 1

    {entries, _} = PermissionBusiness.delete(permission_params.chat_id, permission_params.user_id)

    assert entries == 1

    permissions =
      PermissionBusiness.find_list(
        chat_id: permission_params.chat_id,
        user_id: permission_params.user_id
      )

    assert length(permissions) == 0
  end
end
