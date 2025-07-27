defmodule PolicrMini.Uses do
  @moduledoc false

  import Ecto.Query

  alias PolicrMini.Repo
  alias PolicrMini.Instances.Chat
  alias PolicrMini.Schema.Permission

  @type list_chats_conds :: [
          {:limit, integer},
          {:offset, integer},
          {:order_by, [{:asc | :desc, atom | [atom]}]}
        ]

  def add_chat(params) do
    %Chat{}
    |> Chat.changeset(params)
    |> Repo.insert()
  end

  # TODO：添加测试。
  @doc """
  获取无关联关系约束的群列表。

  ### 查询条件
    - `limit`: 数量限制。默认值为 `10`，最大值为 `35`，超过最大值将视为最大值。
    - `offset`: 偏移位置。默认值为 `0`。
    - `order_by`: 排序方式。默认值为 `[desc: :inserted_at]`（按插入时间降序）。
  """
  @spec list_chats(list_chats_conds()) :: [Chat.t()]
  def list_chats(conds \\ []) do
    limit = Keyword.get(conds, :limit, 10)
    offset = Keyword.get(conds, :offset, 0)
    order_by = Keyword.get(conds, :order_by, desc: :inserted_at)

    from(c in Chat,
      limit: ^limit,
      offset: ^offset,
      order_by: ^order_by
    )
    |> Repo.all()
  end

  @doc """
  基于简单关键字搜索群组列表。
  """
  @spec search_chats(String.t(), list_chats_conds()) :: {any(), Chat.t()}
  def search_chats(keywords, conds \\ []) when is_binary(keywords) do
    fuzzy_keywords = "%" <> String.replace(keywords, ~r/\s+/, "%") <> "%"
    limit = Keyword.get(conds, :limit, 10)
    offset = Keyword.get(conds, :offset, 0)
    order_by = Keyword.get(conds, :order_by, desc: :inserted_at)

    condition =
      dynamic(
        [c],
        ilike(c.title, ^fuzzy_keywords) or ilike(c.description, ^fuzzy_keywords)
      )

    query =
      from(c in Chat,
        where: ^condition,
        limit: ^limit,
        offset: ^offset,
        order_by: ^order_by
      )

    {condition, Repo.all(query)}
  end

  @doc """
  按照条件查询群组数量。
  """
  @spec count_chats(condition :: any()) :: integer()
  def count_chats(condition \\ nil) do
    query =
      if condition do
        # 将 condition 加到 where 条件中，查询符合条件的行数
        from(c in Chat, where: ^condition, select: count(c.id))
      else
        from(c in "pg_stat_user_tables",
          where: c.relname == "chats",
          # 插入的行数 - 删除的行数
          select: fragment("N_TUP_INS - N_TUP_DEL AS COUNT")
        )
      end

    Repo.one(query)
  end

  @doc """
  查找所有已接管群组。
  """
  def find_taken_over_chats do
    from(c in Chat, where: c.is_take_over == true) |> Repo.all()
  end

  @spec all_chats() :: [Chat.t()]
  def all_chats do
    from(c in Chat) |> Repo.all()
  end

  @spec get_permission(integer() | binary(), integer() | binary()) :: Permission.t() | nil
  def get_permission(chat_id, user_id) do
    from(p in Permission,
      where: p.chat_id == ^chat_id,
      where: p.user_id == ^user_id
    )
    |> Repo.one()
  end
end
