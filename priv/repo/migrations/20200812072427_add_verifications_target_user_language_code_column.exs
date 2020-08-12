defmodule PolicrMini.Repo.Migrations.AddVerificationsTargetUserLanguageCodeColumn do
  use PolicrMini.Migration

  def change do
    alter table("verifications") do
      add :target_user_language_code, :string, comment: "目标用户的语言代码"
    end
  end
end
