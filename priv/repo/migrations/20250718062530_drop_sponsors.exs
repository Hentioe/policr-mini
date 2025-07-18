defmodule PolicrMini.Repo.Migrations.DropSponsors do
  use PolicrMini.Migration

  def up do
    drop table(:sponsors)
  end

  def down do
    # Copy from 20210626222802_create_sponsors.exs
    create table(:sponsors) do
      add :title, :string, comment: "称谓"
      add :avatar, :string, comment: "头像"
      add :homepage, :string, comment: "主页"
      add :introduction, :string, comment: "简介"
      add :contact, :string, comment: "联系方式"
      add :uuid, :string, comment: "唯一识别码"
      add :is_official, :boolean, comment: "是否为官方（仅企业赞助身份适用）"

      timestamps()
    end
  end
end
