defmodule PolicrMini.Repo.Migrations.CreteStatisticsUniqueIndexes do
  use Ecto.Migration

  def up do
    # 清空统计表数据
    PolicrMini.Repo.query!("TRUNCATE TABLE statistics")

    # 强制提交上述清空命令，避免后续唯一索引创建失败
    flush()

    # 删除统计数据的联合索引
    drop index(:statistics, [:begin_at, :end_at])

    # 重建新的唯一联合索引
    create unique_index(:statistics, [:chat_id, :verification_status, :begin_at, :end_at])
  end

  def down do
    # 删除重建的新唯一联合索引
    drop unique_index(:statistics, [:chat_id, :verification_status, :begin_at, :end_at])

    # 创建统计数据的原有联合索引
    create index(:statistics, [:begin_at, :end_at])
  end
end
