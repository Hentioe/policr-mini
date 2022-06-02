defmodule PolicrMini.Repo.Migrations.DeleteSchemesVerificationEntrance do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.VerificationEntranceEnum

  def up do
    alter table("schemes") do
      remove :verification_entrance
    end
  end

  def down do
    alter table("schemes") do
      add :verification_entrance, VerificationEntranceEnum.type(), comment: "验证入口"
    end
  end
end
