defmodule PolicrMini.UserBusiness do
  use PolicrMini, business: PolicrMini.Schema.User

  def create(params) do
    %User{} |> User.changeset(params) |> Repo.insert()
  end

  def update(%User{} = user, attrs) do
    user |> User.changeset(attrs) |> Repo.update()
  end

  def fetch(id, params) when is_integer(id) do
    case id |> get() do
      {:error, :not_found, _} -> create(params |> Map.put(:id, id))
      {:ok, user} -> user |> update(params)
    end
  end
end
