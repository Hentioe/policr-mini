defmodule PolicrMini.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, only: [from: 2, dynamic: 2]

  alias PolicrMini.Repo
  alias PolicrMini.Chats.{Scheme, Operation}

  @type scheme_written_returns :: {:ok, Scheme.t()} | {:error, Ecto.Changeset.t()}
  @type operation_written_result :: {:ok, Operation.t()} | {:error, Ecto.Changeset.t()}

  def create_scheme(params) do
    %Scheme{} |> Scheme.changeset(params) |> Repo.insert()
  end

  @default_scheme_chat_id 0
  def create_default_scheme(params) do
    %Scheme{chat_id: @default_scheme_chat_id} |> Scheme.changeset(params) |> Repo.insert()
  end

  def delete_scheme(scheme) when is_struct(scheme, Scheme) do
    Repo.delete(scheme)
  end

  def update_scheme(%Scheme{} = scheme, params) do
    scheme |> Scheme.changeset(params) |> Repo.update()
  end

  @spec find_scheme(integer | binary) :: Scheme.t() | nil
  def find_scheme(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(s in Scheme, where: s.chat_id == ^chat_id, limit: 1) |> Repo.one()
  end

  @type find_scheme_opts :: [{:chat_id, integer()}]

  # TODO: 添加测试。
  @spec find_scheme(find_scheme_opts) :: Scheme.t() | nil
  def find_scheme(options) when is_list(options) do
    filter_chat_id =
      if chat_id = options[:chat_id], do: dynamic([s], s.chat_id == ^chat_id), else: true

    from(s in Scheme, where: ^filter_chat_id) |> Repo.one()
  end

  @spec fetch_scheme(integer | binary) :: scheme_written_returns
  def fetch_scheme(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    case find_scheme(chat_id) do
      nil ->
        create_scheme(%{
          chat_id: chat_id
        })

      scheme ->
        {:ok, scheme}
    end
  end

  @default_scheme %{
    verification_mode: :image,
    seconds: 300,
    timeout_killing_method: :kick,
    wrong_killing_method: :kick,
    is_highlighted: true,
    mention_text: :mosaic_full_name,
    image_answers_count: 4,
    service_message_cleanup: [:joined],
    delay_unban_secs: 300
  }

  @doc """
  获取默认方案，如果不存在将自动创建。
  """
  @spec fetch_default_scheme :: scheme_written_returns
  def fetch_default_scheme do
    Repo.transaction(fn ->
      case find_scheme(@default_scheme_chat_id) || create_default_scheme(@default_scheme) do
        {:ok, scheme} ->
          # 创建了一个新的方案。
          scheme

        {:error, e} ->
          # 创建方案发生错误。
          Repo.rollback(e)

        scheme ->
          # 方案已存在
          migrate_scheme(scheme)
      end
    end)
  end

  @spec migrate_scheme(Scheme.t()) :: Scheme.t() | no_return
  defp migrate_scheme(scheme) do
    # 此处填充后续在方案中添加的新字段，避免方案已存在时这些字段出现 `nil` 值。
    attrs =
      %{}
      |> put_default_attr(scheme, :mention_text)
      |> put_default_attr(scheme, :image_answers_count)
      |> put_default_attr(scheme, :service_message_cleanup)
      |> put_default_attr(scheme, :delay_unban_secs)

    case update_scheme(scheme, attrs) do
      {:ok, scheme} -> scheme
      {:error, e} -> Repo.rollback(e)
    end
  end

  defp put_default_attr(attrs, scheme, field_name) do
    if Map.get(scheme, field_name) != nil,
      do: attrs,
      else: Map.put(attrs, field_name, @default_scheme[field_name])
  end

  # TODO：添加测试。
  @doc """
  创建操作记录。
  """
  @spec create_operation(map()) :: operation_written_result
  def create_operation(params) do
    %Operation{} |> Operation.changeset(params) |> Repo.insert()
  end

  @type find_operations_conts :: [
          {:chat_id, integer},
          {:actions, [:kick | :ban]},
          {:roles, [:system | :admin]},
          {:offset, integer},
          {:limit, integer},
          {:order_by, [{:asc | :desc, atom | [atom]}]},
          {:preload, [:verification]}
        ]

  @default_find_operations_count 25
  @max_find_operations_count 35

  # TODO：添加测试。
  @doc """
  查询操作列表。

  可选查询条件，部分条件存在默认和最大值限制。

  ## 查询条件
  - `chat_id`: 群聊的 ID。
  - `actions`: 包含的执行动作列表，可选值有 `:kick` 和 `:ban`。默认为 `[:kick, :ban]`，不过滤任何执行动作。
  - `roles`: 包含的角色列表，可选值有 `:system` 和 `:admin`。默认为 `[:system, :admin]`，不过滤任何角色。
  - `offset`: 偏移量。默认值为 `0`。
  - `limit`: 数量限制。默认值为 `25`，最大值为 `35`。如果条件中的值大于最大值将会被默认值重写。
  - `order_by`: 排序方式。默认值为 `[desc: :inserted_at]`。
  - `preload`: 预加载的引用数据。
  """
  @spec find_operations(find_operations_conts) :: [Operation.t()]
  def find_operations(conts \\ []) do
    filter_chat_id =
      if chat_id = Keyword.get(conts, :chat_id) do
        dynamic([o], o.chat_id == ^chat_id)
      end

    actions = Keyword.get(conts, :actions, [:kick, :ban])
    roles = Keyword.get(conts, :roles, [:system, :admin])

    offset = Keyword.get(conts, :offset, 0)

    limit =
      if limit = Keyword.get(conts, :limit) do
        if limit > @max_find_operations_count, do: @default_find_operations_count, else: limit
      else
        @default_find_operations_count
      end

    order_by = Keyword.get(conts, :order_by, desc: :inserted_at)
    preload = Keyword.get(conts, :preload, [])

    from(o in Operation,
      where: ^filter_chat_id,
      where: o.role in ^roles and o.action in ^actions,
      offset: ^offset,
      limit: ^limit,
      order_by: ^order_by
    )
    |> Repo.all()
    |> Repo.preload(preload)
  end
end
