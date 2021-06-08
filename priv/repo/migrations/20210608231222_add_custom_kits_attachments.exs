defmodule PolicrMini.Repo.Migrations.AddCustomKitsAttachments do
  use PolicrMini.Migration

  def up do
    alter table("custom_kits") do
      add :attachments, {:array, :string}, comment: "附件列表"
    end
  end

  def down do
    alter table("custom_kits") do
      remove :attachments
    end
  end
end
