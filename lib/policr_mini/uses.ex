defmodule PolicrMini.Uses do
  @moduledoc false

  import Ecto.Query

  alias PolicrMini.Repo
  alias PolicrMini.Instances.Chat

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

  # def chat_seeds do
  #   Enum.map(1..9999, fn i ->
  #     %{
  #       id: i,
  #       title: "种子群 #{i}",
  #       description: "这是一个种子群组：#{i}",
  #       type: :supergroup,
  #       is_take_over: rem(i, 2) == 0,
  #       left: rem(i, 2) == 0,
  #       created_at: DateTime.utc_now(),
  #       updated_at: DateTime.utc_now()
  #     }
  #   end)
  #   |> Enum.map(&add_chat/1)
  # end

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
end
