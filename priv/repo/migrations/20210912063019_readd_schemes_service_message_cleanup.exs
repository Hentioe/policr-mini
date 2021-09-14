defmodule PolicrMini.Repo.Migrations.ReaddSchemesServiceMessageCleanup do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.ServiceMessage

  def up do
    alter table(:schemes) do
      add :service_message_cleanup, {:array, ServiceMessage.type()}, comment: "执行清理的服务消息类型"
    end
  end

  def down do
    alter table(:schemes) do
      remove :service_message_cleanup
    end
  end
end
