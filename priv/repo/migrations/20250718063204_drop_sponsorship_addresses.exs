defmodule PolicrMini.Repo.Migrations.DropSponsorshipAddresses do
  use PolicrMini.Migration

  def up do
    drop table(:sponsorship_addresses)
  end

  def down do
    # Copy from 20211001165220_create_sponsorship_addresses.exs
    create table(:sponsorship_addresses) do
      add :name, :string, comment: "地址名称"
      add :description, :text, comment: "地址说明"
      add :text, :text, comment: "地址文本"
      add :image, :string, comment: "地址图像"

      timestamps()
    end
  end
end
