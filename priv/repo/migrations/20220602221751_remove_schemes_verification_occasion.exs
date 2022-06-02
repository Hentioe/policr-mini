defmodule PolicrMini.Repo.Migrations.DeleteSchemesVerificationOccasion do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.VerificationOccasionEnum

  def up do
    alter table("schemes") do
      remove :verification_occasion
    end
  end

  def down do
    alter table("schemes") do
      add :verification_occasion, VerificationOccasionEnum.type(), comment: "验证场合"
    end
  end
end
