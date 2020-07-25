defmodule PolicrMini.MessageSnapshotBusiness do
  @moduledoc """
  消息快照的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.MessageSnapshot

  def create(params) do
    %MessageSnapshot{} |> MessageSnapshot.changeset(params) |> Repo.insert()
  end

  def update(%MessageSnapshot{} = message_snapshot, params) do
    message_snapshot |> MessageSnapshot.changeset(params) |> Repo.update()
  end
end
