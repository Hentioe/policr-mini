defmodule PolicrMini.Repo.Migrations.AddVerificationSource do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.VerificationSource

  def change do
    alter table(:verifications) do
      add :source, VerificationSource.type(), comment: "来源", default: 0
    end
  end
end
