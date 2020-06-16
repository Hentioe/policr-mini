defmodule PolicrMini.VerificationBusiness do
  use PolicrMini, business: PolicrMini.Schema.Verification

  alias PolicrMini.EctoEnums.{VerificationEntranceEnum, VerificationStatusEnum}

  import Ecto.Query, only: [from: 2]

  @spec create(%{optional(atom() | String.t()) => any()}) ::
          {:ok, Verification.t()} | {:error, Changeset.t()}
  @doc """
  创建验证记录。
  """
  def create(params) when is_map(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  @spec fetch(%{optional(atom() | String.t()) => any()}) ::
          {:ok, Verification.t()} | {:error, Changeset.t()}
  @doc """
  获取或创建验证记录。
  尝试获取已存在的验证记录时，仅获取统一入口下的等待验证记录。
  """
  def fetch(%{chat_id: chat_id, target_user_id: target_user_id} = params) do
    case find_unity_waiting(chat_id, target_user_id) do
      nil -> create(params)
      r -> {:ok, r}
    end
  end

  @spec update(Verification.t(), %{optional(atom() | binary()) => any()}) ::
          {:ok, Verification.t()} | {:error, Changeset.t()}
  @doc """
  更新验证记录。
  """
  def update(%Verification{} = verification, params) do
    verification |> Verification.changeset(params) |> Repo.update()
  end

  @unity_entrance VerificationEntranceEnum.__enum_map__()[:unity]
  @waiting_status VerificationStatusEnum.__enum_map__()[:waiting]

  @spec find_last_unity_waiting(integer()) :: Verification.t() | nil
  @doc """
  查找统一入口下最晚的等待验证。
  """
  def find_last_unity_waiting(chat_id) when is_integer(chat_id) do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.entrance == ^@unity_entrance,
      where: p.status == ^@waiting_status,
      order_by: [desc: p.message_id],
      limit: 1
    )
    |> Repo.one()
  end

  @spec find_first_unity_waiting(integer()) :: Verification.t() | nil
  @doc """
  查找统一入口下最早的等待验证。
  """
  def find_first_unity_waiting(chat_id) when is_integer(chat_id) do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.entrance == ^@unity_entrance,
      where: p.status == ^@waiting_status,
      order_by: [asc: p.message_id],
      limit: 1
    )
    |> Repo.one()
  end

  @spec get_unity_waiting_count(integer()) :: integer()
  @doc """
  获取统一入口的等待验证数量。
  """
  def get_unity_waiting_count(chat_id) do
    from(p in Verification,
      select: count(p.id),
      where: p.chat_id == ^chat_id,
      where: p.entrance == ^@unity_entrance,
      where: p.status == ^@waiting_status
    )
    |> Repo.one()
  end

  @spec find_unity_waiting(integer(), integer()) :: Verification.t() | nil
  @doc """
  查找统一入口的等待验证。
  此函数限定了用户，所以 `user_id` 是必须的。
  """
  def find_unity_waiting(chat_id, user_id) when is_integer(chat_id) and is_integer(user_id) do
    from(p in Verification,
      where: p.chat_id == ^chat_id,
      where: p.target_user_id == ^user_id,
      where: p.entrance == ^@unity_entrance,
      where: p.status == ^@waiting_status,
      order_by: [asc: p.inserted_at],
      limit: 1
    )
    |> Repo.one()
    |> Repo.preload([:chat])
  end

  @spec find_last_unity_message_id(integer()) :: integer() | nil
  @doc """
  获取最后一个统一入口的验证消息编号。
  """
  def find_last_unity_message_id(chat_id) do
    from(p in Verification,
      select: p.message_id,
      where: p.chat_id == ^chat_id,
      where: p.entrance == ^@unity_entrance,
      where: p.status == ^@waiting_status,
      order_by: [desc: p.message_id],
      limit: 1
    )
    |> Repo.one()
  end
end
