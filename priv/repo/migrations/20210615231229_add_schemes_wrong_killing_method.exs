defmodule PolicrMini.Repo.Migrations.AddSchemesWrongKillingMethod do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.KillingMethodEnum

  def up do
    alter table("schemes") do
      add :wrong_killing_method, KillingMethodEnum.type(), comment: "验证错误击杀方法"
    end
  end

  def down do
    alter table("schemes") do
      remove :wrong_killing_method
    end
  end
end
