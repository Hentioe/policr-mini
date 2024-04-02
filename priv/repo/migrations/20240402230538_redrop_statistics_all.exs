defmodule PolicrMini.Repo.Migrations.RedropStatisticsAll do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.StatVerificationStatus

  def up do
    # 删除 statistics 表
    # 删除表的同时也会删除 statistics 表的所有索引
    drop table(:statistics)
  end

  def down do
    create table(:statistics) do
      add :chat_id, references(:chats), comment: "群组编号"
      add :verifications_count, :integer, comment: "验证次数"
      add :languages_top, {:map, {:string, :integer}}, comment: "语言和相应的成员总数"
      add :begin_at, :utc_datetime, comment: "开始时间"
      add :end_at, :utc_datetime, comment: "结束时间"
      add :verification_status, StatVerificationStatus.type(), comment: "验证状态"

      timestamps()
    end

    # 重新建立唯一联合索引
    create unique_index(:statistics, [:chat_id, :verification_status, :begin_at, :end_at])
  end
end
