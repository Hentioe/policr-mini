defmodule PolicrMini.Repo.Migrations.RenameUsersPototoIdToPhoto do
  use PolicrMini.Migration

  def up do
    rename table(:users), :photo_id, to: :photo

    alter table(:users) do
      # 增加 photo 字段的长度到 2048，以安全容纳图片 URL
      modify :photo, :string, size: 2048
    end
  end

  def down do
    rename table(:users), :photo, to: :photo_id

    # 数据长度无法再修改回来，因为新数据的容量可能超出 255
  end
end
