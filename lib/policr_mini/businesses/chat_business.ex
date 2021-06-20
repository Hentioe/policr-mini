defmodule PolicrMini.ChatBusiness do
  @moduledoc """
  群组的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.Chat

  import Ecto.Query, only: [from: 2]

  alias PolicrMini.Schema.Permission
  alias PolicrMini.PermissionBusiness

  @typep written_returns :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map()) :: written_returns()
  def create(params) do
    %Chat{} |> Chat.changeset(params) |> Repo.insert()
  end

  @spec update(Chat.t(), map()) :: written_returns()
  def update(%Chat{} = chat, attrs) do
    chat |> Chat.changeset(attrs) |> Repo.update()
  end

  @spec fetch(integer(), map()) :: written_returns()
  def fetch(id, params) when is_integer(id) do
    case id |> get() do
      {:error, :not_found, _} -> create(params |> Map.put(:id, id))
      {:ok, chat} -> chat |> update(params)
    end
  end

  @spec cancel_takeover(Chat.t()) :: written_returns()
  def cancel_takeover(%Chat{} = chat) do
    chat |> update(%{is_take_over: false})
  end

  @spec reset_administrators!(Chat.t(), [Permission.t()]) :: :ok
  def reset_administrators!(%Chat{} = chat, permissions) when is_list(permissions) do
    permission_params_list =
      permissions |> Enum.map(fn p -> p |> struct(chat_id: chat.id) |> Map.from_struct() end)

    Repo.transaction(fn ->
      # 获取原始用户列表和当前用户列表
      original_user_id_list =
        PermissionBusiness.find_list(chat_id: chat.id) |> Enum.map(fn p -> p.user_id end)

      current_user_id_list = permission_params_list |> Enum.map(fn p -> p.user_id end)

      # 求出当前用户列表中已不包含的原始用户，删除之
      # TODO: 待优化方案：一条语句删除
      original_user_id_list
      |> Enum.filter(fn id -> !(current_user_id_list |> Enum.member?(id)) end)
      |> Enum.each(fn user_id -> PermissionBusiness.delete(chat.id, user_id) end)

      # 将所有管理员权限信息写入（添加或更新）
      permission_params_list
      |> Enum.each(fn params ->
        {:ok, _} = PermissionBusiness.sync(chat.id, params.user_id, params)
      end)

      :ok
    end)
  end

  # TODO：添加测试。
  @doc """
  通过用户查询群组列表。

  将返回指定用户下具有可读权限的群组列表，并按照添加时间排序。
  """
  @spec find_list_by_user(integer) :: [Chat.t()]
  def find_list_by_user(user_id) when is_integer(user_id) do
    from(p in Permission, where: p.user_id == ^user_id and p.readable == true)
    |> Repo.all()
    |> Repo.preload([:chat])
    |> Enum.map(fn p -> p.chat end)
  end

  @max_limit 35

  @type column :: atom
  @type find_list_cont :: [
          {:limit, integer},
          {:offset, integer},
          {:order_by, [{:asc | :desc, column | [column]}]}
        ]

  # 预处理列表查询条件。
  @spec preprocess_find_list_cont(find_list_cont) :: find_list_cont
  defp preprocess_find_list_cont(options) do
    options =
      if limit = Keyword.get(options, :limit) do
        if limit <= @max_limit, do: options, else: Keyword.put(options, :limit, @max_limit)
      else
        Keyword.put(options, :limit, @max_limit)
      end

    options
    |> Keyword.put_new(:offset, 0)
    |> Keyword.put_new(:order_by, desc: :inserted_at)
  end

  # TODO：添加测试。
  @doc """
  查找群列表。


  ## 可选查询条件
  - `limit`: 数量限制。默认值为 `35`，最大值为 `35`，超过最大值将被最大值重写。
  - `offset`: 偏移位置。默认值为 `0`。
  - `order_by`: 排序方式。默认值为 `[desc: :inserted_at]`（按插入时间降序）。
  """
  @spec find_list2(find_list_cont) :: [Chat.t()]
  def find_list2(cont \\ []) when is_list(cont) do
    cont = preprocess_find_list_cont(cont)

    from(c in Chat,
      limit: ^cont[:limit],
      offset: ^cont[:offset],
      order_by: ^cont[:order_by]
    )
    |> Repo.all()
  end

  @spec find_administrators(integer()) :: [Chat.t()]
  def find_administrators(chat_id) do
    from(p in Permission, where: p.chat_id == ^chat_id)
    |> Repo.all()
    |> Repo.preload([:user])
    |> Enum.map(fn p -> p.user end)
  end

  @spec find_takeovered :: [Chat.t()]
  def find_takeovered do
    from(c in Chat, where: c.is_take_over == true) |> Repo.all()
  end

  @keywords_separator_re ~r/ +/

  # TODO: 添加测试。
  @doc """
  搜索群组列表。

  参数 `keywords` 会参与 `title` 和 `description` 两个字段的模糊查询，如以空格分隔即表示具有 `and` 关系的多个关键字条件。
  可选参数 `options` 请参考 `PolicrMini.ChatBusiness.find_list2/1` 函数。

  注意：当前使用空格分隔的关键字仍然具备从左至右的关系，以后可能会顺序无关。
  """
  @spec search(String.t(), find_list_cont) :: [Chat.t()]
  def search(keywords, cont \\ []) do
    cont = preprocess_find_list_cont(cont)
    search_str = "%" <> (keywords |> String.replace(@keywords_separator_re, "%")) <> "%"

    from(c in Chat,
      where: ilike(c.title, ^search_str) or ilike(c.description, ^search_str),
      limit: ^cont[:limit],
      offset: ^cont[:offset],
      order_by: ^cont[:order_by]
    )
    |> Repo.all()
  end
end
