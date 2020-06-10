defmodule PolicrMini.Repo.Migrations.CreatePermissions do
  use PolicrMini.Migration

  def change do
    create table(:permissions) do
      add :chat_id, references(:chats), comment: "聊天编号"
      add :user_id, references(:users), comment: "用户编号"
      add :tg_is_owner, :boolean, comment: "是否为拥有者（同步 TG 权限）"
      add :tg_can_promote_members, :boolean, comment: "是否能添加管理员（同步 TG 权限）"
      add :tg_can_restrict_members, :boolean, comment: "是否能封禁用户（同步 TG 权限）"
      add :readable, :boolean, comment: "是否具有读取权限"
      add :writable, :boolean, comment: "是否具有写入权限"

      timestamps()
    end

    create unique_index("permissions", [:chat_id, :user_id])
  end
end
