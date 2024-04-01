defmodule PolicrMini.Repo.Migrations.AddUsersPhotoId do
  use PolicrMini.Migration

  def up do
    alter table(:users) do
      add :photo_id, :string, comment: "头像 ID"
    end
  end

  def down do
    alter table(:users) do
      remove :photo_id
    end
  end
end
