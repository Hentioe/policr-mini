defmodule PolicrMini.Repo.Migrations.CreateVerificationsChatIdInsertedAtIndexes do
  use Ecto.Migration

  def change do
    # 为验证数据的群聊 ID 和插入时间创建联合索引
    create index(:verifications, [:chat_id, :inserted_at])
  end
end
