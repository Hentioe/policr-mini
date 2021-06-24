defmodule PolicrMini.Repo.Migrations.CreateTerms do
  use PolicrMini.Migration

  def change do
    create table(:terms, primary_key: false) do
      add :id, :bigint, comment: "编号", primary_key: true
      add :content, :text, comment: "条款内容"

      timestamps()
    end
  end
end
