defmodule PolicrMini.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, only: [from: 2, dynamic: 2]

  alias PolicrMini.Repo
  alias PolicrMini.Chats.{Scheme, Operation, Statistic}

  @type scheme_written_returns :: {:ok, Scheme.t()} | {:error, Ecto.Changeset.t()}
  @type operation_written_result :: {:ok, Operation.t()} | {:error, Ecto.Changeset.t()}
  @type statistic_written_result :: {:ok, Statistic.t()} | {:error, Ecto.Changeset.t()}

  @type stat_status :: :passed | :timeout | :wronged | :other

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

  @spec find_today_stat(integer, stat_status) :: Statistic.t() | nil
  def find_today_stat(chat_id, status), do: find_statistic(chat_id, status, range: :today)

  @spec find_yesterday_stat(integer, stat_status) :: Statistic.t() | nil
  def find_yesterday_stat(chat_id, status), do: find_statistic(chat_id, status, range: :yesterday)

  @type stat_dt_cont ::
          [{:range, :today | :yesterday}] | [{:begin_at, DateTime.t()}, {:end_at, DateTime.t()}]

  @spec find_statistic(integer, stat_status, stat_dt_cont) :: Statistic.t() | nil
  defp find_statistic(chat_id, status, stat_dt_cont) do
    {begin_at, end_at} =
      case Keyword.get(stat_dt_cont, :range) do
        :today -> Statistic.today_datetimes()
        :yesterday -> Statistic.yesterday_datetimes()
        nil -> {Keyword.get(stat_dt_cont, :begin_at), Keyword.get(stat_dt_cont, :end_at)}
      end

    from(
      s in Statistic,
      where:
        s.chat_id == ^chat_id and
          s.verification_status == ^status and
          s.begin_at == ^begin_at and
          s.end_at == ^end_at
    )
    |> Repo.one()
  end

  @spec create_statistic(map) :: statistic_written_result
  def create_statistic(params) do
    %Statistic{} |> Statistic.changeset(params) |> Repo.insert()
  end

  @spec update_statistic(Statistic.t(), map) :: statistic_written_result
  def update_statistic(statistic, params) do
    statistic |> Statistic.changeset(params) |> Repo.update()
  end

  def fetch_today_stat(chat_id, status, params) do
    Repo.transaction(fn ->
      case find_today_stat(chat_id, status) || create_statistic(params) do
        {:ok, statistic} ->
          # 创建了一个新的
          statistic

        {:error, e} ->
          # 创建时发生错误
          Repo.rollback(e)

        statistic ->
          # 已存在
          statistic
      end
    end)
  end

  @doc """
  自增一个统计。
  """
  @spec increment_statistic(integer | binary, String.t(), stat_status) :: statistic_written_result

  def increment_statistic(chat_id, language_code, status) do
    language_code = language_code || "unknown"
    {begin_at, end_at} = Statistic.today_datetimes()

    params = %{
      chat_id: chat_id,
      verifications_count: 0,
      languages_top: %{language_code => 0},
      begin_at: begin_at,
      end_at: end_at,
      verification_status: status
    }

    fetch_one = fn -> fetch_today_stat(chat_id, status, params) end

    trans_fun = fn ->
      trans_r = inc_stat_trans(fetch_one, language_code)

      case trans_r do
        {:ok, r} -> r
        e -> e
      end
    end

    # TODO: 此处的事务需保证具有回滚的能力并能够返回错误结果。
    Repo.transaction(trans_fun)
  end

  defp inc_stat_trans(fetch_stat, language_code) do
    case fetch_stat.() do
      {:ok, stat} ->
        verifications_count = stat.verifications_count + 1

        languages_top =
          if count = stat.languages_top[language_code] do
            Map.put(stat.languages_top, language_code, count + 1)
          else
            Map.put(stat.languages_top, language_code, 1)
          end

        update_statistic(stat, %{
          verifications_count: verifications_count,
          languages_top: languages_top
        })

      e ->
        e
    end
  end
end
