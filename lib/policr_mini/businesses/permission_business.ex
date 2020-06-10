defmodule PolicrMini.PermissionBusiness do
  use PolicrMini, business: PolicrMini.Schema.Permission

  import Ecto.Query, only: [from: 2, dynamic: 2]

  def find(chat_id, user_id) when is_integer(chat_id) and is_integer(user_id) do
    from(p in Permission, where: p.chat_id == ^chat_id, where: p.user_id == ^user_id)
    |> Repo.one()
  end

  def create(params) do
    %Permission{} |> Permission.changeset(params) |> Repo.insert()
  end

  def update(%Permission{} = permission, attrs) do
    permission |> Permission.changeset(attrs) |> Repo.update()
  end

  def fetch(chat_id, user_id, params) when is_integer(chat_id) and is_integer(user_id) do
    case find(chat_id, user_id) do
      nil ->
        create(params |> Map.put(:chat_id, chat_id) |> Map.put(:user_id, user_id))

      permission ->
        permission |> update(params)
    end
  end

  def find_list(conds) when is_list(conds) do
    filter_chat_id =
      if chat_id = conds[:chat_id],
        do: dynamic([p], p.chat_id == ^chat_id),
        else: true

    filter_user_id =
      if user_id = conds[:user_id],
        do: dynamic([p], p.user_id == ^user_id),
        else: true

    from(p in Permission, where: ^filter_chat_id, where: ^filter_user_id) |> Repo.all()
  end

  def delete(chat_id, user_id) when is_integer(chat_id) and is_integer(user_id) do
    from(p in Permission, where: p.chat_id == ^chat_id, where: p.user_id == ^user_id)
    |> Repo.delete_all()
  end
end
