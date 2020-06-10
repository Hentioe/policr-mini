defmodule PolicrMini.Repo.Migrations.CreateMessageSnapshots do
  use Ecto.Migration

  def change do
    create table(:message_snapshots) do
      add :chat_id, references(:chats), comment: "聊天编号"
      add :message_id, :integer, comment: "消息编号"
      add :from_user_id, :integer, comment: "来源用户编号"
      add :from_user_name, :string, comment: "来源用户名称"
      add :date, :integer, comment: "日期（时间戳）"
      add :text, :text, comment: "消息文本"
      add :photo_id, :string, comment: "图片编号"
      add :caption, :string, size: 1024, comment: "附件说明"
      add :markup_body, :text, comment: "按钮主体"

      timestamps()
    end
  end
end
