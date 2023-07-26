defmodule PolicrMini.Repo.Migrations.RemoveVerificationsMessageSnapshot do
  use PolicrMini.Migration

  def up do
    alter table(:verifications) do
      remove :message_snapshot_id
    end
  end

  def down do
    alter table(:verifications) do
      add :message_snapshot_id, references(:message_snapshots), comment: "消息快照编号"
    end
  end
end
