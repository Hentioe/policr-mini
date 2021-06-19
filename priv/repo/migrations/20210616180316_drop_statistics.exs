defmodule PolicrMini.Repo.Migrations.DropStatistics do
  use PolicrMini.Migration

  def up do
    drop table(:statistics)
  end

  def down do
    create table(:statistics) do
      add(:chat_id, references(:chats), comment: "群组编号")
      add(:verifications_count, :integer, comment: "验证次数")
      add(:verifications_passed_count, :integer, comment: "验证通过次数")
      add(:join_members_count, :integer, comment: "加入成员数量（无视验证状态）")
      add(:new_members_count, :integer, comment: "新成员数量（验证成功）")
      add(:top_1_language_code, {:map, {:string, :integer}}, comment: "数量第一的语言代码和成员总数")
      add(:top_2_language_code, {:map, {:string, :integer}}, comment: "数量第二的语言代码和成员总数")
      add(:top_3_language_code, {:map, {:string, :integer}}, comment: "数量第三的语言代码和成员总数")
      add(:beginning_date, :date, comment: "开始日期")
      add(:ending_date, :date, comment: "结束日期")

      timestamps()
    end
  end
end
