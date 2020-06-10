defmodule PolicrMini.UserBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.UserBusiness

  def build_params(attrs \\ []) do
    user = Factory.build(:user)
    user |> struct(attrs) |> Map.from_struct()
  end

  test "create/1" do
    user_params = build_params()
    {:ok, user} = UserBusiness.create(user_params)

    assert user.id == user_params.id
    assert user.first_name == user_params.first_name
    assert user.last_name == user_params.last_name
    assert user.username == user_params.username
  end

  test "update/2" do
    user_params = build_params()
    {:ok, user1} = UserBusiness.create(user_params)

    updated_first_name = "新"
    updated_last_name = "一"

    {:ok, user2} =
      user1
      |> UserBusiness.update(%{
        first_name: updated_first_name,
        last_name: updated_last_name
      })

    assert user2.id == user1.id
    assert user2.first_name == updated_first_name
    assert user2.last_name == updated_last_name
    assert user2.username == user1.username
  end

  test "fetch/1" do
    user_params = build_params()
    {:ok, user} = UserBusiness.fetch(123_456_789, user_params)

    assert user.id == user_params.id
    assert user.first_name == user_params.first_name
    assert user.last_name == user_params.last_name
    assert user.username == user_params.username
  end

  test "fetch/1 and existing data" do
    {:ok, user1} = UserBusiness.create(build_params())
    updated_username = "xinyi"
    {:ok, user2} = UserBusiness.fetch(user1.id, build_params(username: updated_username))

    assert user2.username == updated_username
  end

  test "get/1" do
    {:ok, user1} = UserBusiness.create(build_params())
    {:ok, user2} = UserBusiness.get(user1.id)

    assert user1 == user2
  end
end
