defmodule PolicrMini.PermissionBusiness do
  @moduledoc """
  权限的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.Permission

  import Ecto.Query, only: [from: 2, dynamic: 2]

  @doc """
  查找群组内指定用户的权限。
  """
  @spec find(integer, integer) :: Permission.t() | nil
  def find(chat_id, user_id)
      when (is_integer(chat_id) or is_binary(chat_id)) and is_integer(user_id) do
    from(p in Permission, where: p.chat_id == ^chat_id, where: p.user_id == ^user_id)
    |> Repo.one()
  end

  @type permission :: :writable | :readable

  # TODO: 添加测试。
  @doc """
  获取指定用户在指定群组内的权限列表。
  """
  @spec has_permissions(integer | binary, integer) :: [permission]
  def has_permissions(chat_id, user_id) do
    if permission = find(chat_id, user_id) do
      permissions = if permission.writable, do: [:writable], else: []
      permissions = if permission.readable, do: permissions ++ [:readable], else: permissions

      permissions
    else
      []
    end
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

  @type find_list_conds :: [{:chat_id, integer()}, {:user_id, integer()}]
  @spec find_list(find_list_conds()) :: [Permission.t()]
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

  @doc """
  删除群组内指定用户的权限。
  """
  def delete(chat_id, user_id)
      when (is_integer(chat_id) or is_binary(chat_id)) and is_integer(user_id) do
    from(p in Permission, where: p.chat_id == ^chat_id, where: p.user_id == ^user_id)
    |> Repo.delete_all()
  end

  # TODO：添加测试。
  @doc """
  删除指定群组的所有用户权限记录。
  """
  @spec delete_all(integer | binary) :: {integer, any}
  def delete_all(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(p in Permission, where: p.chat_id == ^chat_id)
    |> Repo.delete_all()
  end
end
