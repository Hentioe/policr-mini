defmodule PolicrMini.Repo.Migrations.AddCustomKitsAttachment do
  use PolicrMini.Migration

  def up do
    alter table("custom_kits") do
      add :attachment, :string, comment: "附件"
    end
  end

  def down do
    alter table("custom_kits") do
      remove :attachment
    end
  end
end
