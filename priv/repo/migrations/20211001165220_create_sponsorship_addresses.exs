defmodule PolicrMini.Repo.Migrations.CreateSponsorshipAddresses do
  use PolicrMini.Migration

  def change do
    create table(:sponsorship_addresses) do
      add :name, :string, comment: "地址名称"
      add :description, :text, comment: "地址说明"
      add :text, :text, comment: "地址文本"
      add :image, :string, comment: "地址图像"

      timestamps()
    end
  end
end
