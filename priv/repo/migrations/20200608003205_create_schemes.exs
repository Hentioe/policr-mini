defmodule PolicrMini.Repo.Migrations.CreateSchemes do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.{
    VerificationModeEnum,
    VerificationEntranceEnum,
    VerificationOccasionEnum,
    KillingMethodEnum
  }

  def change do
    create table(:schemes) do
      add :chat_id, references(:chats), comment: "聊天编号"
      add :verification_mode, VerificationModeEnum.type(), comment: "验证模式"
      add :verification_entrance, VerificationEntranceEnum.type(), comment: "验证入口"
      add :verification_occasion, VerificationOccasionEnum.type(), comment: "验证场合"
      add :seconds, :integer, comment: "验证时间（秒）"
      add :killing_method, KillingMethodEnum.type(), comment: "击杀方法"
      add :is_highlighted, :boolean, comment: "是否突出显示"

      timestamps()
    end
  end
end
