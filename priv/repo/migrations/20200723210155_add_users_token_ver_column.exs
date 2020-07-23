defmodule PolicrMini.Repo.Migrations.AddUsersTokenVerColumn do
  use PolicrMini.Migration

  def up do
    alter table("users") do
      add :token_ver, :integer, comment: "令牌版本"
    end

    flush()
    PolicrMini.Repo.update_all("users", set: [token_ver: 0])
  end

  def down do
    alter table("users") do
      remove :token_ver
    end
  end
end
