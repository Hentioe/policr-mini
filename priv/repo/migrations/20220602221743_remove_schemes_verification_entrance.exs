defmodule PolicrMini.Repo.Migrations.DeleteSchemesVerificationEntrance do
  use PolicrMini.Migration

  import EctoEnum

  # 验证入口。此枚举已经删除，但继续被历史 migrations 使用
  defenum(VerificationEntranceEnum, unity: 0, independent: 1)

  def up do
    alter table("schemes") do
      remove :verification_entrance
    end
  end

  def down do
    alter table("schemes") do
      add :verification_entrance, VerificationEntranceEnum.type(), comment: "验证入口"
    end
  end
end
