defmodule PolicrMini.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, only: [from: 2, dynamic: 2]

  alias PolicrMini.Repo
  alias PolicrMini.Chats.{Scheme, Operation, Statistic, CustomKit, Verification}
  alias PolicrMini.Chats.CustomKit

  @type scheme_written_returns :: {:ok, Scheme.t()} | {:error, Ecto.Changeset.t()}
  @type operation_written_result :: {:ok, Operation.t()} | {:error, Ecto.Changeset.t()}
  @type statistic_written_result :: {:ok, Statistic.t()} | {:error, Ecto.Changeset.t()}
  @type custom_kit_change_result :: {:ok, CustomKit.t()} | {:error, Ecto.Changeset.t()}
  @type verification_change_result :: {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}

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

  # TODO: 添加测试
  def upsert_scheme(chat_id, params) when is_integer(chat_id) do
    set = Enum.into(params, [])

    %Scheme{chat_id: chat_id}
    |> Scheme.changeset(params)
    |> Repo.insert(
      on_conflict: [set: set],
      conflict_target: :chat_id
    )
  end

  def upsert_scheme(chat_id, params) when is_binary(chat_id) do
    upsert_scheme(String.to_integer(chat_id), params)
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

  @type find_operations_cont :: [
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
  @spec find_operations(find_operations_cont) :: [Operation.t()]
  def find_operations(cont \\ []) do
    filter_chat_id =
      if chat_id = Keyword.get(cont, :chat_id) do
        dynamic([o], o.chat_id == ^chat_id)
      end

    actions = Keyword.get(cont, :actions, [:kick, :ban])
    roles = Keyword.get(cont, :roles, [:system, :admin])

    offset = Keyword.get(cont, :offset, 0)

    limit =
      if limit = Keyword.get(cont, :limit) do
        if limit > @max_find_operations_count, do: @default_find_operations_count, else: limit
      else
        @default_find_operations_count
      end

    order_by = Keyword.get(cont, :order_by, desc: :inserted_at)
    preload = Keyword.get(cont, :preload, [])

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

  def get_or_create_today_stat(chat_id, status, params) do
    case find_today_stat(chat_id, status) do
      nil -> create_statistic(params)
      stat -> {:ok, stat}
    end
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

    case get_or_create_today_stat(chat_id, status, params) do
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

  # TODO: 添加测试
  @spec get_custom_kits_count(integer | binary) :: integer()
  def get_custom_kits_count(chat_id) do
    from(c in CustomKit,
      select: count(c.id),
      where: ^dynamic([c], c.chat_id == ^chat_id)
    )
    |> Repo.one()
  end

  @max_custom_kits_count 55

  @spec create_custom_kit(map()) ::
          custom_kit_change_result | {:error, %{description: String.t()}}

  def create_custom_kit(params) do
    chat_id = params[:chat_id] || params["chat_id"]

    if PolicrMini.Chats.get_custom_kits_count(chat_id) >= @max_custom_kits_count do
      {:error, %{description: "自定义问答已达到数量上限"}}
    else
      %CustomKit{} |> CustomKit.changeset(params) |> Repo.insert()
    end
  end

  @spec update_custom_kit(CustomKit.t(), map) :: custom_kit_change_result
  def update_custom_kit(%CustomKit{} = custom_kit, params) do
    custom_kit |> CustomKit.changeset(params) |> Repo.update()
  end

  def delete_custom_kit(%CustomKit{} = custom_kit) do
    custom_kit |> Repo.delete()
  end

  @spec find_custom_kits(integer) :: [CustomKit.t()]
  def find_custom_kits(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id) |> Repo.all()
  end

  def random_custom_kit(chat_id) do
    from(c in CustomKit, where: c.chat_id == ^chat_id, order_by: fragment("RANDOM()"), limit: 1)
    |> Repo.one()
  end

  @doc """
  创建验证记录。
  """
  @spec create_verification(map) :: verification_change_result
  def create_verification(params) when is_map(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  @doc """
  获取或创建指定群聊和用户的等待完成验证。
  """
  @spec get_or_create_pending_verification(integer, integer, map) ::
          verification_change_result
  def get_or_create_pending_verification(chat_id, target_user_id, params \\ %{}) do
    case find_pending_verification(chat_id, target_user_id) do
      nil ->
        params =
          params
          |> Map.put(:chat_id, chat_id)
          |> Map.put(:target_user_id, target_user_id)
          |> Map.put(:status, :waiting)

        create_verification(params)

      r ->
        {:ok, r}
    end
  end

  @spec find_pending_verification(integer, integer) :: Verification.t() | nil
  def find_pending_verification(chat_id, target_user_id)
      when chat_id < 0 and target_user_id > 0 do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.target_user_id == ^target_user_id,
      where: p.status == :waiting,
      order_by: [asc: p.inserted_at],
      limit: 1
    )
    |> Repo.one()
    |> Repo.preload([:chat])
  end

  @doc """
  更新验证记录。
  """
  @spec update_verification(Verification.t(), map) :: verification_change_result
  def update_verification(%Verification{} = verification, params) do
    verification |> Verification.changeset(params) |> Repo.update()
  end

  @doc """
  查找指定群聊的最后一个等待完成的验证。
  """
  @spec find_last_pending_verification(integer) :: Verification.t() | nil
  def find_last_pending_verification(chat_id) do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.status == :waiting,
      order_by: [desc: p.message_id],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  获取指定群聊的等待完成的验证个数。
  """
  @spec get_pending_verification_count(integer) :: integer
  def get_pending_verification_count(chat_id) do
    from(p in Verification,
      select: count(p.id),
      where: p.chat_id == ^chat_id,
      where: p.status == :waiting
    )
    |> Repo.one()
  end

  @doc """
  获取指定群聊的最后一个验证的消息编号。
  """
  @spec find_last_verification_message_id(integer) :: integer | nil
  def find_last_verification_message_id(chat_id) do
    from(p in Verification,
      select: p.message_id,
      where: p.chat_id == ^chat_id,
      where: not is_nil(p.message_id),
      order_by: [desc: p.message_id],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  查找所有等待完成的验证。
  """
  @spec find_all_pending_verifications :: [Verification.t()]
  def find_all_pending_verifications do
    from(p in Verification,
      where: p.status == :waiting,
      order_by: [asc: p.inserted_at]
    )
    |> Repo.all()
  end

  @type find_verifications_total_cont_status :: :passed | :timeout
  @type find_verifications_total_cont :: [{:status, find_verifications_total_cont_status}]

  @doc """
  查找指定条件的验证总个数。
  """
  @spec find_verifications_total(find_verifications_total_cont) :: integer
  def find_verifications_total(cont \\ []) do
    filter_status =
      if status = Keyword.get(cont, :status) do
        dynamic([v], v.status == ^status)
      else
        true
      end

    from(v in Verification, select: count(v.id), where: ^filter_status)
    |> Repo.one()
  end

  @default_verification_list_limit 25
  @max_verification_list_limit @default_verification_list_limit

  @type find_verifications_cont :: [
          {:chat_id, integer | binary},
          {:status, {:in, [atom]} | {:not_in, [atom]}},
          {:limit, integer},
          {:offset, integer},
          {:order_by, [{:desc | :asc, atom | [atom]}]}
        ]

  @doc """
  查找验证记录列表。

  可选参数表示查询条件，部分条件存在默认和最大值限制。

  ## 查询条件
  - `chat_id`: 群组的 ID。
  - `status`: 状态条件，值为 `{:in, [status, ...]}` 或 `{:not_in, [status, ...]}`。
  - `limit`: 数量限制。默认值为 `25`，最大值为 `25`。如果条件中的值大于最大值将会被最大值重写。
  - `offset`: 偏移量。默认值为 `0`。
  - `order_by`: 排序方式，默认值为 `[desc: :inserted_at]`。
  """
  @spec find_verifications(find_verifications_cont) :: [Verification.t()]
  def find_verifications(cont \\ []) do
    filter_chat_id =
      if chat_id = Keyword.get(cont, :chat_id) do
        dynamic([v], v.chat_id == ^chat_id)
      else
        true
      end

    filter_status =
      case Keyword.get(cont, :status) do
        {:in, status} -> dynamic([v], v.status in ^status)
        {:not_in, status} -> dynamic([v], v.status not in ^status)
        _ -> true
      end

    limit =
      if limit = Keyword.get(cont, :limit) do
        if limit > @max_verification_list_limit, do: @max_verification_list_limit, else: limit
      else
        @default_verification_list_limit
      end

    offset = Keyword.get(cont, :offset, 0)
    order_by = Keyword.get(cont, :order_by, desc: :inserted_at)

    from(v in Verification,
      where: ^filter_chat_id,
      where: ^filter_status,
      limit: ^limit,
      offset: ^offset,
      order_by: ^order_by
    )
    |> Repo.all()
  end
end
