defmodule PolicrMini.Repo.Migrations.AddCustomKitsPhotosColumn do
  use PolicrMini.Migration

  def change do
    alter table("custom_kits") do
      add :photos, {:array, :string}, comment: "图片列表"
    end
  end
end
