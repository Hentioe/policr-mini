defmodule PolicrMini.UserBusiness do
  @moduledoc """
  用户业务功能的实现。
  """

  use PolicrMini, business: PolicrMini.Schema.User

  import Ecto.Query, only: [from: 2]

  @type written_returns :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map) :: written_returns
  def create(params) do
    %User{token_ver: 0} |> User.changeset(params) |> Repo.insert()
  end

  @spec update(User.t(), map) :: written_returns
  def update(user, attrs) do
    user |> User.changeset(attrs) |> Repo.update()
  end

  @spec fetch(integer, map) :: written_returns
  def fetch(id, params) when is_integer(id) do
    case id |> get() do
      {:error, :not_found, _} -> create(params |> Map.put(:id, id))
      {:ok, user} -> user |> update(params)
    end
  end

  @spec upgrade_token_ver(integer()) :: boolean()
  def upgrade_token_ver(user_id) do
    {rows, _} =
      from(u in User, where: u.id == ^user_id, update: [inc: [token_ver: 1]])
      |> Repo.update_all([])

    rows > 0
  end
end
