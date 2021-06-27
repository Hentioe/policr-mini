defmodule PolicrMini.SponsorBusinessTest do
  use PolicrMini.DataCase

  alias PolicrMini.Factory
  alias PolicrMini.SponsorBusiness

  def build_params(attrs \\ []) do
    sponsor = Factory.build(:sponsor)

    sponsor
    |> struct(attrs)
    |> Map.from_struct()
  end

  test "create/1" do
    sponsor_params = build_params()
    {:ok, sponsor} = SponsorBusiness.create(sponsor_params)

    assert sponsor.title == sponsor_params.title
    assert sponsor.avatar == sponsor_params.avatar
    assert sponsor.homepage == sponsor_params.homepage
    assert sponsor.introduction == sponsor_params.introduction
    assert sponsor.contact == sponsor_params.contact
    assert sponsor.uuid == sponsor_params.uuid
    assert sponsor.is_official == sponsor_params.is_official
  end

  test "update/2" do
    sponsor_params = build_params()
    {:ok, sponsor1} = SponsorBusiness.create(sponsor_params)

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

    {:ok, sponsor2} = SponsorBusiness.update(sponsor1, params)

    assert sponsor2.title == updated_title
    assert sponsor2.avatar == updated_avatar
    assert sponsor2.homepage == updated_homepage
    assert sponsor2.introduction == updated_introduction
    assert sponsor2.contact == updated_contact
    assert sponsor2.uuid == updated_uuid
    assert sponsor2.is_official == updated_is_official
  end

  test "delete/1" do
    {:ok, _} = SponsorBusiness.create(build_params())
    {:ok, sponsor2} = SponsorBusiness.create(build_params(uuid: "yyyy-yyyy-yyyy-yyyy"))

    sponsors = SponsorBusiness.find_list()

    assert length(sponsors) == 2

    {:ok, _} = SponsorBusiness.delete(sponsor2)

    sponsors = SponsorBusiness.find_list()

    assert length(sponsors) == 1
  end

  test "find_list/1" do
    {:ok, _} = SponsorBusiness.create(build_params())
    {:ok, _} = SponsorBusiness.create(build_params(uuid: "yyyy-yyyy-yyyy-yyyy"))

    sponsors = SponsorBusiness.find_list()

    assert length(sponsors) == 2
  end
end
