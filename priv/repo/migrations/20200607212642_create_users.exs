defmodule PolicrMini.Repo.Migrations.CreateUsers do
  use PolicrMini.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :integer, comment: "用户编号", primary_key: true
      add :first_name, :string, comment: "姓"
      add :last_name, :string, comment: "名"
      add :username, :string, comment: "用户名"

      timestamps()
    end
  end
end
