defmodule PolicrMini.UserBusiness do
  @moduledoc """
  用户业务功能的实现。
  """

  use PolicrMini, business: PolicrMini.Schema.User

  @deprecated "Use PolicrMini.Accounts.add_user/1 instead"
  @spec create(map) :: written_returns
  def create(params) do
    %User{token_ver: 0} |> User.changeset(params) |> Repo.insert()
  end

  @deprecated "Use PolicrMini.Accounts.update_user/2 instead"
  @spec update(User.t(), map) :: written_returns
  def update(user, attrs) do
    user |> User.changeset(attrs) |> Repo.update()
  end

  @deprecated "Use PolicrMini.Accounts.upsert_user/2 instead"
  @spec fetch(integer, map) :: written_returns
  def fetch(id, params) when is_integer(id) do
    case id |> get() do
      {:error, :not_found, _} -> create(params |> Map.put(:id, id))
      {:ok, user} -> user |> update(params)
    end
  end
end
