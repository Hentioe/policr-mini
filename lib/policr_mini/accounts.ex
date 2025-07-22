defmodule PolicrMini.Accounts do
  @moduledoc false

  use PolicrMini.Context

  alias PolicrMini.Repo
  alias PolicrMini.Schema.User

  def add_user(params) when is_map(params) do
    %User{}
    |> User.changeset(params)
    |> Repo.insert()
  end
end
