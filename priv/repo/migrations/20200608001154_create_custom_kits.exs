defmodule PolicrMini.Repo.Migrations.CreateCustomKits do
  use PolicrMini.Migration

  def change do
    create table(:custom_kits) do
      add :chat_id, references(:chats), comment: "聊天编号"
      add :title, :string, comment: "问题标题"
      add :answer_body, :text, comment: "答案主体"

      timestamps()
    end
  end
end
