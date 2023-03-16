defmodule PolicrMini.Repo.Migrations.DeleteSchemesVerificationOccasion do
  use PolicrMini.Migration

  import EctoEnum

  # 验证场合。此枚举已经删除，但继续被历史 migrations 使用
  defenum(VerificationOccasionEnum, private: 0, public: 1)

  def up do
    alter table("schemes") do
      remove :verification_occasion
    end
  end

  def down do
    alter table("schemes") do
      add :verification_occasion, VerificationOccasionEnum.type(), comment: "验证场合"
    end
  end
end
