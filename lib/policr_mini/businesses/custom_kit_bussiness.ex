defmodule PolicrMini.CustomKitBusiness do
  use PolicrMini, business: PolicrMini.Schema.CustomKit

  import Ecto.Query, only: [from: 2]

  def create(params) do
    %CustomKit{} |> CustomKit.changeset(params) |> Repo.insert()
  end

  def update(%CustomKit{} = custom_kit, params) do
    custom_kit |> CustomKit.changeset(params) |> Repo.update()
  end

  def delete(%CustomKit{} = custom_kit) do
    custom_kit |> Repo.delete()
  end

  def find_list(chat_id) when is_integer(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id) |> Repo.all()
  end

  def random_one(chat_id) when is_integer(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id, order_by: fragment("RANDOM()"), limit: 1)
    |> Repo.one()
  end
end
