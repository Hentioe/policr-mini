defmodule PolicrMini.SchemeBusiness do
  use PolicrMini, business: PolicrMini.Schema.Scheme

  import Ecto.Query, only: [from: 2]

  def create(params) do
    %Scheme{} |> Scheme.changeset(params) |> Repo.insert()
  end

  def update(%Scheme{} = scheme, params) do
    scheme |> Scheme.changeset(params) |> Repo.update()
  end

  def find(chat_id) when is_integer(chat_id) do
    from(s in Scheme, where: s.chat_id == ^chat_id) |> Repo.one()
  end

  def fetch(chat_id) when is_integer(chat_id) do
    case chat_id |> find() do
      nil ->
        create(%{
          chat_id: chat_id
        })

      scheme ->
        {:ok, scheme}
    end
  end
end
