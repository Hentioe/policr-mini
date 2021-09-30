defmodule PolicrMini.Repo.Migrations.AddSponsorshipHistroiesHidden do
  use PolicrMini.Migration

  def up do
    alter table(:sponsorship_histories) do
      add :hidden, :boolean, comment: "被隐藏"
    end
  end

  def down do
    alter table(:sponsorship_histories) do
      remove :hidden
    end
  end
end
