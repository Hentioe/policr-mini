defmodule PolicrMini.Repo.Migrations.AddChatsLeft do
  use PolicrMini.Migration

  def up do
    alter table(:chats) do
      add :left, :boolean, comment: "是否已离开"
    end
  end

  def down do
    alter table(:chats) do
      remove :left
    end
  end
end
