defmodule PolicrMini.Repo.Migrations.RemoveSchemesServiceMessageCleanup do
  use PolicrMini.Migration

  def up do
    alter table(:schemes) do
      remove :service_message_cleanup
    end
  end

  def down do
    alter table(:schemes) do
      add :service_message_cleanup, :boolean, comment: "是否清理服务消息"
    end
  end
end
