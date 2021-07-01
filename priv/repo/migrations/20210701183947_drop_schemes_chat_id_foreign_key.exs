defmodule PolicrMini.Repo.Migrations.DropSchemesChatIdForeignKey do
  use PolicrMini.Migration

  def up do
    drop constraint(:schemes, "schemes_chat_id_fkey")

    alter table(:schemes) do
      modify :chat_id, :bigint, null: true, comment: "群组 ID"
    end
  end

  def down do
    alter table(:schemes) do
      modify :chat_id, references(:chats), null: false, comment: "群组 ID"
    end
  end
end
