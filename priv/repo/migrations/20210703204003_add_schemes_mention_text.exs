defmodule PolicrMini.Repo.Migrations.AddSchemesMentionText do
  use PolicrMini.Migration

  alias PolicrMini.EctoEnums.MentionText

  def up do
    alter table(:schemes) do
      add :mention_text, MentionText.type(), comment: "提及文本"
    end
  end

  def down do
    alter table(:schemes) do
      remove :mention_text
    end
  end
end
