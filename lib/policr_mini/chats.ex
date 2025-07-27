defmodule PolicrMini.Chats do
  @moduledoc """
  The Chats context.
  """

  import Ecto.Query, only: [from: 2, dynamic: 2]

  alias Ecto.Changeset
  alias PolicrMini.Repo
  alias PolicrMini.Chats.{Scheme, Operation, CustomKit, Verification}
  alias PolicrMini.Chats.CustomKit
  alias PolicrMini.Schema.Permission

  require Logger

  @type vsource :: :joined | :join_request

  @type scheme_change_result :: {:ok, Scheme.t()} | {:error, Ecto.Changeset.t()}
  @type operation_written_result :: {:ok, Operation.t()} | {:error, Ecto.Changeset.t()}
  @type custom_kit_change_result :: {:ok, CustomKit.t()} | {:error, Ecto.Changeset.t()}
  @type verification_change_result :: {:ok, Verification.t()} | {:error, Ecto.Changeset.t()}

  @type stat_status :: :passed | :timeout | :wronged | :other

  @spec load_scheme(integer() | binary()) :: {:ok, Scheme.t()} | {:error, :not_found}
  def load_scheme(id) when is_integer(id) or is_binary(id) do
    case Repo.get(Scheme, id) do
      nil -> {:error, :not_found}
      scheme -> {:ok, scheme}
    end
  end

  def create_scheme(params) do
    %Scheme{} |> Scheme.changeset(params) |> Repo.insert()
  end

  @default_scheme_chat_id 0
  def create_default_scheme do
    %Scheme{chat_id: @default_scheme_chat_id}
    |> Scheme.changeset(Scheme.default_params())
    |> Repo.insert()
  end

  def delete_scheme(scheme) when is_struct(scheme, Scheme) do
    Repo.delete(scheme)
  end

  def update_scheme(%Scheme{} = scheme, params) do
    scheme |> Scheme.changeset(params) |> Repo.update()
  end

  @deprecated "Use get_scheme_by_chat_id/1 instead"
  @spec find_scheme(integer | binary) :: Scheme.t() | nil
  def find_scheme(chat_id) when is_integer(chat_id) or is_binary(chat_id) do
    from(s in Scheme, where: s.chat_id == ^chat_id, limit: 1) |> Repo.one()
  end

  @spec find_or_init_scheme(integer | binary) :: scheme_change_result
  def find_or_init_scheme(chat_id) do
    case find_scheme(chat_id) do
      nil ->
        create_scheme(%{
          chat_id: chat_id
        })

      scheme ->
        {:ok, scheme}
    end
  end

  @deprecated "Use upsert_scheme/2 instead"
  @spec find_or_init_scheme!(integer | binary) :: Scheme.t()
  def find_or_init_scheme!(chat_id) do
    case find_or_init_scheme(chat_id) do
      {:ok, scheme} -> scheme
      {:error, e} -> raise e
    end
  end

  def get_scheme_by_chat_id(id) when is_integer(id) or is_binary(id) do
    from(s in Scheme, where: s.chat_id == ^id, limit: 1) |> Repo.one()
  end

  def upsert_scheme(chat_id, params) when is_integer(chat_id) do
    updated_at = DateTime.utc_now()
    set = Enum.into(params, updated_at: updated_at)

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

  def upsert_scheme!(chat_id, params) do
    case upsert_scheme(chat_id, params) do
      {:ok, scheme} -> scheme
      {:error, e} -> raise e
    end
  end

  @doc """
  获取默认方案，如果不存在将自动创建。
  """
  @spec default_scheme :: scheme_change_result
  def default_scheme do
    Repo.transaction(fn ->
      case find_scheme(@default_scheme_chat_id) || create_default_scheme() do
        {:ok, scheme} ->
          # 创建了一个新的默认方案
          scheme

        {:error, e} ->
          # 创建方案发生错误，回滚事务
          Repo.rollback(e)

        scheme ->
          # 方案已存在，迁移到最新的方案中
          migrate_scheme(scheme)
      end
    end)
  end

  @doc """
  迁移方案到具有默认值的最新数据中。将旧方案迁移到新的具有默认值的版本，避免已存在方案的新字段出现 `nil` 值。

  目前迁移仅用于全局的默认方案，对于群聊自己的方案不应该执行此操作。
  """
  @spec migrate_scheme(Scheme.t()) :: Scheme.t() | no_return
  def migrate_scheme(scheme) do
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
    if scheme |> Map.get(field_name) |> is_nil() do
      Map.put(attrs, field_name, Scheme.default_param(field_name))
    else
      attrs
    end
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

  @deprecated "Use add_custom/1 instead"
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

  @deprecated "Use update_custom/2 instead"
  @spec update_custom_kit(CustomKit.t(), map) :: custom_kit_change_result
  def update_custom_kit(%CustomKit{} = custom_kit, params) do
    custom_kit |> CustomKit.changeset(params) |> Repo.update()
  end

  @deprecated "Use delete_custom/1 instead"
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

  @spec load_custom(integer() | binary()) :: {:ok, CustomKit.t()} | {:error, :not_found}
  def load_custom(id) when is_integer(id) or is_binary(id) do
    case Repo.get(CustomKit, id) do
      nil -> {:error, :not_found}
      custom -> {:ok, custom}
    end
  end

  @spec add_custom(map()) :: {:ok, CustomKit.t()} | {:error, Changeset.t() | :max_reached}
  def add_custom(params) do
    chat_id = params[:chat_id] || params["chat_id"]

    if get_custom_kits_count(chat_id) >= @max_custom_kits_count do
      {:error, :max_reached}
    else
      %CustomKit{} |> CustomKit.changeset(params) |> Repo.insert()
    end
  end

  @spec update_custom(CustomKit.t(), map()) :: {:ok, CustomKit.t()} | {:error, Changeset.t()}
  def update_custom(custom, params) when is_struct(custom, CustomKit) do
    custom |> CustomKit.changeset(params) |> Repo.update()
  end

  @spec delete_custom(CustomKit.t()) :: {:ok, CustomKit.t()} | {:error, Changeset.t()}
  def delete_custom(custom) when is_struct(custom, CustomKit) do
    custom |> Repo.delete()
  end

  @doc """
  创建验证记录。
  """
  @deprecated "Use PolicrMini.Chats.add_verification/1 instead"
  @spec create_verification(map) :: verification_change_result
  def create_verification(params) when is_map(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  @doc """
  创建一条验证记录。
  """
  def add_verification(params) when is_map(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  @doc """
  获取最早一条验证记录的插入时间。
  """
  def first_verification_inserted_at do
    from(v in Verification, select: min(v.inserted_at))
    |> Repo.one()
  end

  @doc """
  获取或创建指定群聊和用户的等待完成验证。

  函数名缩写来源：`get_cr_pend_verif` -> `get_or_create_pending_verification`。
  """
  @spec get_cr_pend_verif(integer, integer, map) :: verification_change_result
  def get_cr_pend_verif(chat_id, target_user_id, params \\ %{}) do
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
  @spec get_pending_verification_count(integer, vsource) :: integer
  def get_pending_verification_count(chat_id, source) do
    from(p in Verification,
      select: count(p.id),
      where: p.chat_id == ^chat_id,
      where: p.status == :waiting,
      where: p.source == ^source
    )
    |> Repo.one()
  end

  @doc """
  获取指定群聊的最后一个验证的消息编号。
  """
  @spec find_last_verification_message_id(integer, vsource) :: integer | nil
  def find_last_verification_message_id(chat_id, source) do
    from(p in Verification,
      select: p.message_id,
      where: p.chat_id == ^chat_id,
      where: p.source == ^source,
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

  @doc """
  自增指定验证的发送次数。
  """
  @spec increase_verification_send_times(integer) :: :ok | :ignore
  def increase_verification_send_times(id) when not is_nil(id) do
    case Repo.update_all(from(v in Verification, where: v.id == ^id, select: v.send_times),
           inc: [send_times: 1]
         ) do
      {1, _} ->
        :ok

      {count, r} when count > 1 ->
        # TODO: 完善：进入此分支后回滚更新。
        # 自增发送次数的验证不止一个
        Logger.warning(
          "Increase verification send times, but more than one verification found: #{inspect(count: count, result: r)}"
        )

        :ok

      {0, _} ->
        :ignore
    end
  end

  @doc """
  查找指定群聊中指定用户的权限。
  """
  @spec find_user_permission(integer, integer) :: Permission.t() | nil
  def find_user_permission(chat_id, user_id) do
    from(p in Permission, where: p.chat_id == ^chat_id, where: p.user_id == ^user_id)
    |> Repo.one()
  end

  @type pmode :: :writable | :readable | :owner

  # TODO: 添加测试。
  @doc """
  获取指定群聊下用户的权限模型列表。

  **注意：此函数对机器人已离开的群聊永远返回空列表**
  """
  @spec get_pmodes(integer | binary, integer) :: [pmode]
  def get_pmodes(chat_id, user_id) do
    if permission = find_user_permission(chat_id, user_id) do
      chat = Repo.preload(permission, [:chat]).chat

      # 检查群组是否已离开
      if chat.left == true do
        []
      else
        pmodes = if permission.writable, do: [:writable], else: []
        pmodes = if permission.readable, do: pmodes ++ [:readable], else: pmodes
        pmodes = if permission.tg_is_owner, do: pmodes ++ [:owner], else: pmodes

        pmodes
      end
    else
      []
    end
  end

  @doc """
  获取特定时间区间内的验证列表，不包含正在进行的验证。
  """
  @spec range_verifications(integer, DateTime.t(), DateTime.t()) :: [Verification.t()]
  def range_verifications(chat_id, start, stop) do
    from(v in Verification,
      where: v.chat_id == ^chat_id,
      where: v.inserted_at >= ^start,
      where: v.inserted_at <= ^stop,
      where: v.status != :waiting
    )
    |> Repo.all()
  end

  def add_permission(params) do
    %Permission{} |> Permission.changeset(params) |> Repo.insert()
  end
end
