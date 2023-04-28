defmodule PolicrMini.Repo.Migrations.CreateVerificationsIndexes do
  use Ecto.Migration

  def change do
    create index(:verifications, [:chat_id, :target_user_id, :status])
  end
end
