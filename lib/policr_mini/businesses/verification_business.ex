defmodule PolicrMini.VerificationBusiness do
  use PolicrMini, business: PolicrMini.Schema.Verification

  alias PolicrMini.EctoEnums.{VerificationEntranceEnum, VerificationStatusEnum}

  import Ecto.Query, only: [from: 2]

  def create(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  def update(%Verification{} = verification, params) do
    verification |> Verification.changeset(params) |> Repo.update()
  end

  @unity_entrance VerificationEntranceEnum.__enum_map__()[:unity]
  @waiting_status VerificationStatusEnum.__enum_map__()[:waiting]

  @spec find_last_unity_waiting(integer()) :: Verification.t()
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

  @spec find_first_unity_waiting(integer()) :: Verification.t()
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
  def get_unity_waiting_count(chat_id) do
    from(p in Verification,
      select: count(p.id),
      where: p.chat_id == ^chat_id,
      where: p.entrance == ^@unity_entrance,
      where: p.status == ^@waiting_status
    )
    |> Repo.one()
  end

  @spec find_unity_waiting(integer(), integer()) :: Verification.t()
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
end
