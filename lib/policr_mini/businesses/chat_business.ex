defmodule PolicrMini.ChatBusiness do
  @moduledoc """
  群组的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Instances.Chat

  import Ecto.Query, only: [from: 2]

  alias PolicrMini.Schema.Permission

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
