defmodule PolicrMini.Repo.Migrations.AddPermissionsCustomizedColumn do
  use PolicrMini.Migration

  def change do
    alter table("permissions") do
      add :customized, :boolean, comment: "是否已定制"
    end
  end
end
