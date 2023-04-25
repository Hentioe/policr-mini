defmodule PolicrMini.VerificationBusiness do
  @moduledoc """
  验证的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.Verification

  alias PolicrMini.EctoEnums.VerificationStatusEnum

  import Ecto.Query, only: [from: 2, dynamic: 2]

  @doc """
  创建验证记录。
  """
  @spec create(%{optional(atom() | String.t()) => any()}) :: written_returns()
  def create(params) when is_map(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  @doc """
  获取或创建验证记录。
  尝试获取已存在的验证记录时，仅获取统一入口下的等待验证记录。
  """
  @spec fetch(%{optional(atom() | String.t()) => any()}) :: written_returns()
  def fetch(%{chat_id: chat_id, target_user_id: target_user_id} = params) do
    case find_waiting_verification(chat_id, target_user_id) do
      nil -> create(params)
      r -> {:ok, r}
    end
  end

  @doc """
  更新验证记录。
  """
  @spec update(Verification.t(), %{optional(atom() | binary()) => any()}) :: written_returns()
  def update(%Verification{} = verification, params) do
    verification |> Verification.changeset(params) |> Repo.update()
  end

  @waiting_status VerificationStatusEnum.__enum_map__()[:waiting]

  @doc """
  查找特定群聊中最后一个正在等待的验证。
  """
  @spec find_last_waiting_verification(integer | binary) :: Verification.t() | nil
  def find_last_waiting_verification(chat_id) do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.status == ^@waiting_status,
      order_by: [desc: p.message_id],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  获取统特定群聊的等待验证数量。
  """
  @spec get_waiting_count(integer | binary) :: integer
  def get_waiting_count(chat_id) do
    from(p in Verification,
      select: count(p.id),
      where: p.chat_id == ^chat_id,
      where: p.status == ^@waiting_status
    )
    |> Repo.one()
  end

  @doc """
  查找指定用户在特定群聊中等待的验证。
  """
  @spec find_waiting_verification(integer | binary, integer | binary) :: Verification.t() | nil
  def find_waiting_verification(chat_id, user_id)
      when is_integer(chat_id) and is_integer(user_id) do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.target_user_id == ^user_id,
      where: p.status == ^@waiting_status,
      order_by: [asc: p.inserted_at],
      limit: 1
    )
    |> Repo.one()
    |> Repo.preload([:chat])
  end

  @doc """
  获取特定群聊中最后一个验证的消息编号。
  """
  @spec find_last_verification_message_id(integer | binary) :: integer | nil
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
  查找所有等待中的验证列表。
  """
  @spec find_all_waiting_verifications :: [Verification.t()]
  def find_all_waiting_verifications do
    from(p in Verification,
      where: p.status == ^@waiting_status,
      order_by: [asc: p.inserted_at]
    )
    |> Repo.all()
  end

  # TODO：使用 `find_total/1` 替代并删除。
  @doc """
  获取验证总数。
  """
  @spec get_total :: integer()
  def get_total do
    from(v in Verification, select: count(v.id)) |> Repo.one()
  end

  @type find_total_cont_status :: :passed | :timeout
  @type find_total_cont :: [{:status, find_total_cont_status}]

  # TODO：添加测试。
  @doc """
  查找验证的总次数。
  """
  @spec find_total(find_total_cont) :: integer
  def find_total(cont \\ []) do
    filter_status =
      if status = Keyword.get(cont, :status) do
        build_find_total_status_filter(status)
      else
        true
      end

    from(v in Verification, select: count(v.id), where: ^filter_status) |> Repo.one()
  end

  defp build_find_total_status_filter(:passed) do
    dynamic([v], v.status == ^VerificationStatusEnum.__enum_map__()[:passed])
  end

  defp build_find_total_status_filter(:timeout) do
    dynamic([v], v.status == ^VerificationStatusEnum.__enum_map__()[:timeout])
  end

  @type find_list_cont :: [
          {:chat_id, integer | binary},
          {:limit, integer},
          {:offset, integer},
          {:status, :passed | :not_passed | :all},
          {:order_by, [{:desc | :asc, atom | [atom]}]}
        ]

  @default_find_list_limit 25
  @max_find_list_limit @default_find_list_limit

  @doc """
  查找验证记录列表。

  可选参数表示查询条件，部分条件存在默认和最大值限制。

  ## 查询条件
  - `chat_id`: 群组的 ID。
  - `limit`: 数量限制。默认值为 `25`，最大值为 `25`。如果条件中的值大于最大值将会被最大值重写。
  - `offset`: 偏移量。默认值为 `0`。
  - `order_by`: 排序方式，默认值为 `[desc: :inserted_at]`。
  """
  @spec find_list(find_list_cont) :: [Verification.t()]
  def find_list(cont \\ []) do
    filter_chat_id =
      if chat_id = Keyword.get(cont, :chat_id) do
        dynamic([v], v.chat_id == ^chat_id)
      else
        true
      end

    limit =
      if limit = Keyword.get(cont, :limit) do
        if limit > @max_find_list_limit, do: @max_find_list_limit, else: limit
      else
        @default_find_list_limit
      end

    offset = Keyword.get(cont, :offset, 0)
    order_by = Keyword.get(cont, :order_by, desc: :inserted_at)

    filter_status = build_find_list_status_filter(Keyword.get(cont, :status))

    from(v in Verification,
      where: ^filter_chat_id,
      where: ^filter_status,
      limit: ^limit,
      offset: ^offset,
      order_by: ^order_by
    )
    |> Repo.all()
  end

  defp build_find_list_status_filter(:passed) do
    dynamic([v], v.status == ^VerificationStatusEnum.__enum_map__()[:passed])
  end

  defp build_find_list_status_filter(:not_passed) do
    dynamic([v], v.status != ^VerificationStatusEnum.__enum_map__()[:passed])
  end

  defp build_find_list_status_filter(_), do: true
end
