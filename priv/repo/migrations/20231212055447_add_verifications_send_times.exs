defmodule PolicrMini.Repo.Migrations.AddVerificationsSendTimes do
  use PolicrMini.Migration

  def change do
    alter table(:verifications) do
      add :send_times, :integer, comment: "发送次数"
    end
  end
end
