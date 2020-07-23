defmodule PolicrMini.UserBusiness do
  @moduledoc """
  用户的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.User

  @type return_writed :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map()) :: return_writed
  def create(params) do
    %User{token_ver: 0} |> User.changeset(params) |> Repo.insert()
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
