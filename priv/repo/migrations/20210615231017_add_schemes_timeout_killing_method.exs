defmodule PolicrMini.Repo.Migrations.AddSchemesTimeoutKillingMethod do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.KillingMethodEnum

  def up do
    alter table("schemes") do
      add :timeout_killing_method, KillingMethodEnum.type(), comment: "验证超时击杀方法"
    end
  end

  def down do
    alter table("schemes") do
      remove :timeout_killing_method
    end
  end
end
