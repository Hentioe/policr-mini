defmodule PolicrMini.Schema.SponsorTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Schema.Sponsor

  describe "schema" do
    test "schema metadata" do
      assert Sponsor.__schema__(:source) == "sponsors"

      assert Sponsor.__schema__(:fields) ==
               [
                 :id,
                 :title,
                 :avatar,
                 :homepage,
                 :introduction,
                 :contact,
                 :uuid,
                 :is_official,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert Sponsor.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    sponsor = Factory.build(:sponsor)

    updated_title = "宇宙电报发射中心"
    updated_avatar = "/uploaded/universe.jpg"
    updated_homepage = "https://universe.org"
    updated_introduction = "我们用电报研究外星生命"
    updated_contact = "@universe"
    updated_uuid = "yyyy-yyyy-yyyy-yyyy"
    updated_is_official = true

    params = %{
      "title" => updated_title,
      "avatar" => updated_avatar,
      "homepage" => updated_homepage,
      "introduction" => updated_introduction,
      "contact" => updated_contact,
      "uuid" => updated_uuid,
      "is_official" => updated_is_official
    }

    changes = %{
      title: updated_title,
      avatar: updated_avatar,
      homepage: updated_homepage,
      introduction: updated_introduction,
      contact: updated_contact,
      uuid: updated_uuid,
      is_official: updated_is_official
    }

    changeset = Sponsor.changeset(sponsor, params)
    assert changeset.params == params
    assert changeset.data == sponsor
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :contact,
             :uuid
           ]

    assert changeset.valid?
  end
end
