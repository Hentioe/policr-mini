defmodule PolicrMini.Repo.Migrations.AddCustomKitsAnswersColumn do
  use PolicrMini.Migration

  def change do
    alter table("custom_kits") do
      add :answers, {:array, :string}, comment: "答案列表"
    end
  end
end
