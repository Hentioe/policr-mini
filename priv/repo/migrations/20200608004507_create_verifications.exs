defmodule PolicrMini.Repo.Migrations.CreateVerifications do
  use PolicrMini.Migration
  alias PolicrMini.EctoEnums.VerificationStatus

  import EctoEnum

  # 验证入口。此枚举已经删除，但继续被历史 migrations 使用
  defenum(VerificationEntranceEnum, unity: 0, independent: 1)

  def change do
    create table(:verifications) do
      add :chat_id, references(:chats), comment: "聊天编号"
      add :message_snapshot_id, references(:message_snapshots), comment: "消息快照编号"
      add :target_user_id, :bigint, comment: "目标用户的编号"
      add :target_user_name, :string, comment: "目标用户的名称（全名）"
      add :entrance, VerificationEntranceEnum.type(), comment: "入口类型"
      add :message_id, :integer, comment: "消息编号"
      add :indices, {:array, :integer}, comment: "正确索引（多个）"
      add :seconds, :integer, comment: "剩余时间"
      add :status, VerificationStatus.type(), comment: "验证状态"
      add :chosen, :integer, comment: "被选中索引"

      timestamps()
    end
  end
end
