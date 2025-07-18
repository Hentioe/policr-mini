defmodule PolicrMini.Repo.Migrations.DropSponsorshipHistories do
  use PolicrMini.Migration

  def up do
    drop table(:sponsorship_histories)
  end

  def down do
    # Copy from 20210626223101_create_sponsorship_histories.exs
    # and 20210929162945_add_sponsorship_histroies_hidden.exs
    create table(:sponsorship_histories) do
      add :sponsor_id, references(:sponsors), comment: "赞助者编号"
      add :expected_to, :string, comment: "期望用于"
      add :amount, :integer, comment: "金额"
      add :has_reached, :boolean, comment: "是否已达成"
      add :reached_at, :utc_datetime, comment: "达成时间"
      add :hidden, :boolean, comment: "被隐藏"

      timestamps()
    end
  end
end
