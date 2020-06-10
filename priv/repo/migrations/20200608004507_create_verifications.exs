defmodule PolicrMini.Repo.Migrations.CreateVerifications do
  use PolicrMini.Migration
  alias PolicrMini.EctoEnums.VerificationStatusEnum

  def change do
    create table(:verifications) do
      add :chat_id, references(:chats), comment: "聊天编号"
      add :message_snapshot_id, references(:message_snapshots), comment: "消息快照编号"
      add :message_id, :integer, comment: "消息编号"
      add :indices, {:array, :integer}, comment: "正确索引（多个）"
      add :seconds, :integer, comment: "剩余时间"
      add :status, VerificationStatusEnum.type(), comment: "验证状态"
      add :chosen, :integer, comment: "被选中索引"

      timestamps()
    end
  end
end
