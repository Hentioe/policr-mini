defmodule PolicrMini.Repo.Migrations.DeleteSchemesIsHighlighted do
  use PolicrMini.Migration

  def up do
    alter table("schemes") do
      remove :is_highlighted
    end
  end

  def down do
    alter table("schemes") do
      add :is_highlighted, :boolean, comment: "是否突出显示"
    end
  end
end
