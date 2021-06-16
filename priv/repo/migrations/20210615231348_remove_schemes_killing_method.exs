defmodule PolicrMini.Repo.Migrations.RemoveSchemesKillingMethod do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.KillingMethodEnum

  def up do
    alter table("schemes") do
      remove :killing_method
    end
  end

  def down do
    alter table("schemes") do
      add :killing_method, KillingMethodEnum.type(), comment: "击杀方法"
    end
  end
end
