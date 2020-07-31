defmodule PolicrMini.Repo.Migrations.CreateSchemesChatIdUniqueIndex do
  use PolicrMini.Migration

  def change do
    create unique_index(:schemes, [:chat_id])
  end
end
