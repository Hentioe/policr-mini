defmodule PolicrMini.Repo.Migrations.CreateSponsorshipHistories do
  use PolicrMini.Migration

  def change do
    create table(:sponsorship_histories) do
      add :sponsor_id, references(:sponsors), comment: "赞助者编号"
      add :expected_to, :string, comment: "期望用于"
      add :amount, :integer, comment: "金额"
      add :has_reached, :boolean, comment: "是否已达成"
      add :reached_at, :utc_datetime, comment: "达成时间"

      timestamps()
    end
  end
end
