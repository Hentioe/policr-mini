defmodule PolicrMini.Instances.SponsorshipAddressTest do
  use ExUnit.Case

  alias PolicrMini.Factory
  alias PolicrMini.Instances.SponsorshipAddress

  describe "schema" do
    test "schema metadata" do
      assert SponsorshipAddress.__schema__(:source) == "sponsorship_addresses"

      assert SponsorshipAddress.__schema__(:fields) ==
               [
                 :id,
                 :name,
                 :description,
                 :text,
                 :image,
                 :inserted_at,
                 :updated_at
               ]
    end

    assert SponsorshipAddress.__schema__(:primary_key) == [:id]
  end

  test "changeset/2" do
    sponsorship_address = Factory.build(:sponsorship_address)

    updated_name = "USDT (ERC20)"
    updated_description = "如美元般稳定的加密货币 USDT 的转账地址，仅限 ERC20 网络。"
    updated_text = "--------------------------"
    updated_image = "usdt-erc20-qrcode.jpg"

    params = %{
      "name" => updated_name,
      "description" => updated_description,
      "text" => updated_text,
      "image" => updated_image
    }

    changes = %{
      name: updated_name,
      description: updated_description,
      text: updated_text,
      image: updated_image
    }

    changeset = SponsorshipAddress.changeset(sponsorship_address, params)
    assert changeset.params == params
    assert changeset.data == sponsorship_address
    assert changeset.changes == changes
    assert changeset.validations == []

    assert changeset.required == [
             :name
           ]

    assert changeset.valid?
  end
end
