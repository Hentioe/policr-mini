defmodule PolicrMini.Repo.Migrations.AlertMessageSnapshotsUserId do
  use Ecto.Migration

  def change do
    alter table(:message_snapshots) do
      modify :from_user_id, :bigint
    end
  end
end
