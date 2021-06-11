defmodule PolicrMini.Repo.Migrations.AddMessageSnaphostsAttachment do
  use PolicrMini.Migration

  def up do
    alter table("message_snapshots") do
      add :attachment, :string, comment: "消息附件"
    end
  end

  def down do
    alter table("message_snapshots") do
      remove :attachment
    end
  end
end
