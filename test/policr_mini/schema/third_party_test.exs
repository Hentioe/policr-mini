defmodule PolicrMini.Schema.ThirdPartyTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.ThirdParty

  describe "schema" do
    test "schema metadata" do
      assert ThirdParty.__schema__(:source) == "third_parties"

      assert ThirdParty.__schema__(:fields) ==
               [
                 :id,
                 :name,
                 :bot_username,
                 :bot_avatar,
                 :homepage,
                 :description,
                 :hardware,
                 :running_days,
                 :version,
                 :is_forked,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert ThirdParty.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    third_party = Factory.build(:third_party)

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

    changes = %{
      name: updated_name,
      bot_username: updated_bot_username,
      bot_avatar: updated_bot_avatar,
      homepage: updated_homepage,
      description: updated_description,
      hardware: updated_hardware,
      running_days: updated_running_days,
      version: updated_version,
      is_forked: updated_is_forked
    }

    changeset = ThirdParty.changeset(third_party, params)
    assert changeset.params == params
    assert changeset.data == third_party
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :name,
             :bot_username,
             :homepage,
             :running_days,
             :version,
             :is_forked
           ]

    assert changeset.valid?
  end
end
