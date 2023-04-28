defmodule PolicrMini.Repo.Migrations.AddOperationsChatId do
  use PolicrMini.Migration

  def up do
    alter table("operations") do
      add :chat_id, references(:chats), comment: "聊天编号"
    end

    # 强制执行上面的修改
    flush()

    # 批量更新 operations 关联的 chat_id
    sql = """
    UPDATE operations o SET chat_id = (
    SELECT c.id FROM chats c
    JOIN verifications v ON v.chat_id = c.id
    WHERE v.id = o.verification_id
    )
    """

    PolicrMini.Repo.query!(sql)
  end

  def down do
    alter table("operations") do
      remove :chat_id
    end
  end
end
