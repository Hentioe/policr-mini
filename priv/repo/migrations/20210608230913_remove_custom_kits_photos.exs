defmodule PolicrMini.Repo.Migrations.RemoveCustomKitsPhotos do
  use PolicrMini.Migration

  def up do
    alter table("custom_kits") do
      remove :photos
    end
  end

  def down do
    alter table("custom_kits") do
      add :photos, {:array, :string}, comment: "图片列表"
    end
  end
end
