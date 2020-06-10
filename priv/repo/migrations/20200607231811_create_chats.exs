defmodule PolicrMini.Repo.Migrations.CreateChats do
  use PolicrMini.Migration
  alias PolicrMini.EctoEnums.ChatTypeEnum

  def change do
    create table(:chats, primary_key: false) do
      add :id, :integer, comment: "聊天编号", primary_key: true
      add :type, ChatTypeEnum.type(), comment: "聊天类型"
      add :title, :string, comment: "标题"
      add :small_photo_id, :string, comment: "小尺寸聊天图片编号"
      add :big_photo_id, :string, comment: "大尺寸聊天图片编号"
      add :username, :string, comment: "用户名"
      add :description, :text, comment: "说明"
      add :invite_link, :string, comment: "邀请链接"
      add :is_take_over, :boolean, comment: "是否被接管"

      timestamps()
    end
  end
end
