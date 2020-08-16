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

  @default_limit 25
  @max_limit @default_limit
  @type find_list_cont :: [
          {:chat_id, integer | binary},
          {:user_id, integer},
          {:limit, integer},
          {:offset, integer},
          {:preload, [:chat | :user]}
        ]
  @doc """
  查找权限列表。

  可选参数 `cont` 表示查询条件。可指定用户或指定群组来过滤列表（亦或组合起来），以及数量限制和偏移量。

  *注意*：即使不限制数量也存在最大数量限制，参数无法突破这个限制。

  ## 条件参数
  - `chat_id`: 群组的 ID。
  - `user_id`: 用户的 ID。
  - `limit`: 数量限制。默认值为 `25`，可允许的最大值也是 `25`。如果值大于最大限制会被重写为 `25`。
  - `offset`: 偏移量，默认值为 `0`。

  无参数表示表示。
  """
  @spec find_list(find_list_cont) :: [Permission.t()]
  def find_list(cont \\ []) when is_list(cont) do
    filter_chat_id =
      if chat_id = cont[:chat_id],
        do: dynamic([p], p.chat_id == ^chat_id),
        else: true

    filter_user_id =
      if user_id = cont[:user_id],
        do: dynamic([p], p.user_id == ^user_id),
        else: true

    limit =
      if limit = cont[:limit] do
        if limit > @max_limit, do: @max_limit, else: limit
      else
        @max_limit
      end

    offset = Keyword.get(cont, :offset, 0)
    preload = Keyword.get(cont, :preload, [])

    from(p in Permission,
      where: ^filter_chat_id,
      where: ^filter_user_id,
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
    |> Repo.preload(preload)
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
