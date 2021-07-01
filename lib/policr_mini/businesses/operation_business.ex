defmodule PolicrMini.OperationBusiness do
  @moduledoc """
  操作的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.Operation

  alias PolicrMini.Schema.Verification

  import Ecto.Query, only: [from: 2, dynamic: 2]

  # TODO：添加测试。
  @doc """
  创建操作记录。
  """
  @spec create(params) :: written_returns
  def create(params) do
    %Operation{} |> Operation.changeset(params) |> Repo.insert()
  end

  @type field :: atom
  @type find_list_cont :: [
          {:chat_id, integer},
          {:action, :kick | :ban | :all},
          {:role, :system | :admin | :all},
          {:offset, integer},
          {:limit, integer},
          {:order_by, [{:asc | :desc, field | [field]}]},
          {:preload, [:verification]}
        ]

  @default_find_list_limit 25
  @max_find_list_limit @default_find_list_limit

  # TODO：添加测试。
  @doc """
  查询操作列表。

  可选参数表示查询条件，部分条件存在默认和最大值限制。

  ## 查询条件
  - `chat_id`: 群组的 ID。
  - `action`: 执行的动作。可为 `:kick` 或 `:ban` 或 `:all`，默认值为 `:all` 表示不限制执行动作。
  - `role`: 操作人角色。可为 `:system` 或 `:admin` 或 `:all`，默认值为 `:all` 表示不限制操作人角色。
  - `offset`: 偏移量。默认值为 `0`。
  - `limit`: 数量限制。默认值为 `25`，最大值为 `25`。如果条件中的值大于最大值将会被最大值重写。
  - `order_by`: 排序方式。默认值为 `[desc: :inserted_at]`。
  - `preload`: 预加载的引用数据。
  """
  @spec find_list(find_list_cont) :: [Operation.t()]
  def find_list(cont \\ []) do
    offset = Keyword.get(cont, :offset, 0)

    filter_chat_id = build_chat_id_filter(Keyword.get(cont, :chat_id))
    filter_action = build_action_filter(Keyword.get(cont, :action, :all))
    filter_role = build_role_filter(Keyword.get(cont, :role, :all))

    limit =
      if limit = Keyword.get(cont, :limit) do
        if limit > @max_find_list_limit, do: @default_find_list_limit, else: limit
      else
        @default_find_list_limit
      end

    order_by = Keyword.get(cont, :order_by, desc: :inserted_at)

    preload = Keyword.get(cont, :preload, [])

    from(o in Operation,
      join: v in Verification,
      on: o.verification_id == v.id,
      where: ^filter_chat_id,
      where: ^filter_action,
      where: ^filter_role,
      offset: ^offset,
      limit: ^limit,
      order_by: ^order_by
    )
    |> Repo.all()
    |> Repo.preload(preload)
  end

  defp build_chat_id_filter(nil), do: true
  defp build_chat_id_filter(chat_id), do: dynamic([o, v], v.chat_id == ^chat_id)
  defp build_action_filter(:all), do: true
  defp build_action_filter(action), do: dynamic([o, v], o.action == ^action)
  defp build_role_filter(:all), do: true
  defp build_role_filter(role), do: dynamic([o, v], o.role == ^role)
end
