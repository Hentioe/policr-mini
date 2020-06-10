defmodule PolicrMini.MessageSnapshotBusiness do
  use PolicrMini, business: PolicrMini.Schema.MessageSnapshot

  def create(params) do
    %MessageSnapshot{} |> MessageSnapshot.changeset(params) |> Repo.insert()
  end

  def update(%MessageSnapshot{} = message_snapshot, params) do
    message_snapshot |> MessageSnapshot.changeset(params) |> Repo.update()
  end
end
