defmodule PolicrMini.Repo.Migrations.AddSchemesImageAnswersCount do
  use PolicrMini.Migration

  def up do
    alter table(:schemes) do
      add :image_answers_count, :integer, comment: "图片验证答案数"
    end
  end

  def down do
    alter table(:schemes) do
      remove :image_answers_count
    end
  end
end
