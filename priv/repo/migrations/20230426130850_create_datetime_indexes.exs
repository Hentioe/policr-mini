defmodule PolicrMini.Repo.Migrations.CreateDatetimeIndexes do
  use Ecto.Migration

  def change do
    # 为验证数据的插入时间创建索引
    create index(:verifications, [:inserted_at])
    # 为操作数据的插入时间创建索引
    create index(:operations, [:inserted_at])
    # 为统计数据的开始日期时间和结束日期时间创建联合索引
    create index(:statistics, [:begin_at, :end_at])
  end
end
