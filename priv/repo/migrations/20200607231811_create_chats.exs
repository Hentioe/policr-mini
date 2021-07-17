defmodule PolicrMini.Repo.Migrations.CreateChats do
  use PolicrMini.Migration
  alias PolicrMini.EctoEnums.ChatType

  def change do
    create table(:chats, primary_key: false) do
      add :id, :bigint, comment: "聊天编号", primary_key: true
      add :type, ChatType.type(), comment: "聊天类型"
      add :title, :string, comment: "标题"
      add :small_photo_id, :string, comment: "小尺寸聊天图片编号"
      add :big_photo_id, :string, comment: "大尺寸聊天图片编号"
      add :username, :string, comment: "用户名"
      add :description, :text, comment: "说明"
      add :invite_link, :string, comment: "邀请链接"
      add :is_take_over, :boolean, comment: "是否被接管"
      add :tg_can_add_web_page_previews, :boolean, comment: "是否能添加网页预览（同步 TG 权限）"
      add :tg_can_change_info, :boolean, comment: "是否能修改信息（同步 TG 权限）"
      add :tg_can_invite_users, :boolean, comment: "是否能邀请用户（同步 TG 权限）"
      add :tg_can_pin_messages, :boolean, comment: "是否能置顶消息（同步 TG 权限）"
      add :tg_can_send_media_messages, :boolean, comment: "是否能发送媒体消息（同步 TG 权限）"
      add :tg_can_send_messages, :boolean, comment: "是否能发送消息（同步 TG 权限）"
      add :tg_can_send_other_messages, :boolean, comment: "是否能发送其它消息（同步 TG 权限）"
      add :tg_can_send_polls, :boolean, comment: "是否能发送调查（同步 TG 权限）"

      timestamps()
    end
  end
end
