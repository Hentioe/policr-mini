defmodule PolicrMini.Repo.Migrations.CreateThirdParties do
  use PolicrMini.Migration

  def change do
    create table(:third_parties) do
      add :name, :string, comment: "实例名称"
      add :bot_username, :string, comment: "机器人用户名"
      add :bot_avatar, :string, comment: "机器人头像"
      add :homepage, :string, comment: "主页"
      add :description, :string, comment: "实例描述"
      add :operator, :string, comment: "运营者"
      add :hardware, :string, comment: "硬件配置"
      add :running_days, :integer, comment: "持续运行天数"
      add :version, :string, comment: "版本"
      add :is_forked, :boolean, comment: "是否为分叉的版本"

      timestamps()
    end
  end
end
