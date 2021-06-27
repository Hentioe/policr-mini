defmodule PolicrMini.Repo.Migrations.CreateSponsors do
  use PolicrMini.Migration

  def change do
    create table(:sponsors) do
      add :title, :string, comment: "称谓"
      add :avatar, :string, comment: "头像"
      add :homepage, :string, comment: "主页"
      add :introduction, :string, comment: "简介"
      add :contact, :string, comment: "联系方式"
      add :unique_code, :string, comment: "唯一码"
      add :is_official, :boolean, comment: "是否为官方（仅企业赞助身份适用）"

      timestamps()
    end
  end
end
