defmodule PolicrMini.Accounts do
  @moduledoc false

  use PolicrMini.Context

  import Ecto.Query, only: [from: 2]

  alias PolicrMini.Repo
  alias PolicrMini.Schema.User

  @spec get_user(integer | String.t()) :: User.t() | nil
  def get_user(id) when is_integer(id) or is_binary(id) do
    Repo.get(User, id)
  end

  def add_user(params) when is_map(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end

  def upsert_user(id, params) when (is_integer(id) or is_binary(id)) and is_map(params) do
    set = Enum.into(params, [])

    %User{id: id}
    |> User.changeset(params)
    |> Repo.insert(
      on_conflict: [set: set],
      conflict_target: :id
    )
  end

  def update_user(user, params) do
    user
    |> User.changeset(params)
    |> Repo.update()
  end

  @spec upgrade_token_ver(integer() | binary()) :: boolean()
  def upgrade_token_ver(user_id) when is_integer(user_id) or is_binary(user_id) do
    {rows, _} =
      from(u in User,
        where: u.id == ^user_id,
        update: [inc: [token_ver: 1]]
      )
      |> Repo.update_all([])

    rows > 0
  end
end
