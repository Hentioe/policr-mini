defmodule PolicrMini.Repo.Migrations.RemoveCustomKitsAnswerBodyColumn do
  use PolicrMini.Migration

  def up do
    alter table("custom_kits") do
      remove :answer_body
    end
  end

  def down do
    alter table("custom_kits") do
      add :answer_body, :text, comment: "答案主体"
    end
  end
end
