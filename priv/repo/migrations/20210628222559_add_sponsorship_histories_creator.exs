defmodule PolicrMini.Repo.Migrations.AddSponsorshipHistoriesCreator do
  use PolicrMini.Migration

  def up do
    alter table(:sponsorship_histories) do
      add :creator, :bigint, comment: "创建者（TG 用户 ID）"
    end
  end

  def down do
    alter table(:sponsorship_histories) do
      remove :creator
    end
  end
end
