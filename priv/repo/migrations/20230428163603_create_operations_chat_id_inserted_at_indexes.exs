defmodule PolicrMini.Repo.Migrations.CreateOperationsChatIdInsertedAtIndexes do
  use Ecto.Migration

  def change do
    # 为操作数据的群聊 ID 和插入时间创建联合索引
    create index(:operations, [:chat_id, :inserted_at])
  end
end
