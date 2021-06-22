defmodule PolicrMini.ThirdPartyBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.ThirdPartyBusiness

  def build_params(attrs \\ []) do
    third_party = Factory.build(:third_party)

    third_party
    |> struct(attrs)
    |> Map.from_struct()
  end

  test "create/1" do
    third_party_params = build_params()
    {:ok, third_party} = ThirdPartyBusiness.create(third_party_params)

    assert third_party.name == third_party_params.name
    assert third_party.bot_username == third_party_params.bot_username
    assert third_party.bot_avatar == third_party_params.bot_avatar
    assert third_party.homepage == third_party_params.homepage
    assert third_party.description == third_party_params.description
    assert third_party.hardware == third_party_params.hardware
    assert third_party.running_days == third_party_params.running_days
    assert third_party.version == third_party_params.version
    assert third_party.is_forked == third_party_params.is_forked
  end

  test "update/2" do
    third_party_params = build_params()
    {:ok, third_party1} = ThirdPartyBusiness.create(third_party_params)

    updated_name = "测试实例"
    updated_bot_username = "policr_mini_beta_bot"
    updated_bot_avatar = "beta.jpg"
    updated_homepage = "https://mini-beta.telestd.me"
    updated_description = "这是一个修正开发分支数个 BUG 的测试版本"
    updated_hardware = "1C2GB"
    updated_running_days = 99
    updated_version = "0.0.1-beta.1"
    updated_is_forked = true

    params = %{
      "name" => updated_name,
      "bot_username" => updated_bot_username,
      "bot_avatar" => updated_bot_avatar,
      "homepage" => updated_homepage,
      "description" => updated_description,
      "hardware" => updated_hardware,
      "running_days" => updated_running_days,
      "version" => updated_version,
      "is_forked" => updated_is_forked
    }

    {:ok, third_party2} = third_party1 |> ThirdPartyBusiness.update(params)

    assert third_party2.name == updated_name
    assert third_party2.bot_username == updated_bot_username
    assert third_party2.bot_avatar == updated_bot_avatar
    assert third_party2.homepage == updated_homepage
    assert third_party2.description == updated_description
    assert third_party2.hardware == updated_hardware
    assert third_party2.running_days == updated_running_days
    assert third_party2.version == updated_version
    assert third_party2.is_forked == updated_is_forked
  end

  test "reset_running_days/1" do
    {:ok, third_party1} = ThirdPartyBusiness.create(build_params())

    assert third_party1.running_days == 1

    {:ok, third_party2} = ThirdPartyBusiness.reset_running_days(third_party1)

    assert third_party2.id == third_party1.id
    assert third_party2.running_days == 0
  end

  test "find_list/1" do
    {:ok, third_party1} = ThirdPartyBusiness.create(build_params())
    {:ok, third_party2} = ThirdPartyBusiness.create(build_params(running_days: 2))

    [third_party3, third_party4] = ThirdPartyBusiness.find_list()

    assert third_party3.id == third_party2.id
    assert third_party4.id == third_party1.id

    {:ok, third_party5} = ThirdPartyBusiness.reset_running_days(third_party2)

    [_, third_party6] = ThirdPartyBusiness.find_list()

    assert third_party6.id == third_party5.id
  end
end
