defmodule PolicrMini.Repo.Migrations.AddSchemeDelayUnbanSecs do
  use PolicrMini.Migration

  def up do
    alter table(:schemes) do
      add :delay_unban_secs, :integer, comment: "延迟解封时长（秒）"
    end
  end

  def down do
    alter table(:schemes) do
      remove :delay_unban_secs
    end
  end
end
