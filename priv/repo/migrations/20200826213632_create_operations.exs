defmodule PolicrMini.Repo.Migrations.CreateOperations do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.{OperationActionEnum, OperationRoleEnum}

  def change do
    create table(:operations) do
      add :verification_id, references(:verifications), comment: "验证编号"
      add :action, OperationActionEnum.type(), comment: "执行动作"
      add :role, OperationRoleEnum.type(), comment: "操作人身份"

      timestamps()
    end
  end
end
