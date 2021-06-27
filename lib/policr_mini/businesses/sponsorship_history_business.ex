defmodule PolicrMini.SponsorshipHistoryBusiness do
  @moduledoc """
  赞助历史的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.SponsorshipHistory

  alias PolicrMini.SponsorBusiness

  import Ecto.Query, only: [from: 2, dynamic: 2]

  @type written_returns :: {:ok, SponsorshipHistory.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map) :: written_returns
  def create(params) do
    %SponsorshipHistory{} |> SponsorshipHistory.changeset(params) |> Repo.insert()
  end

  # TODO: 添加测试。
  @spec create_with_sponsor(map) :: {:ok, SponsorshipHistory.t()} | {:error, any}
  def create_with_sponsor(params) do
    sponsor = params["sponsor"]

    Repo.transaction(fn ->
      with {:ok, sponsor} <- SponsorBusiness.create(sponsor),
           {:ok, sponsorship_history} <- create(Map.put(params, "sponsor_id", sponsor.id)) do
        sponsorship_history
      else
        e -> e
      end
    end)
  end

  @spec update(SponsorshipHistory.t(), map) :: written_returns
  def update(sponsorship_history, params) do
    sponsorship_history |> SponsorshipHistory.changeset(params) |> Repo.update()
  end

  # TODO: 添加测试。
  @spec update_with_create_sponsor(SponsorshipHistory.t(), map) ::
          {:ok, SponsorshipHistory.t()} | {:error, any}
  def update_with_create_sponsor(sponsorship_history, params) do
    sponsor = params["sponsor"]

    Repo.transaction(fn ->
      with {:ok, sponsor} <- SponsorBusiness.create(sponsor),
           {:ok, sponsorship_history} <-
             update(sponsorship_history, Map.put(params, "sponsor_id", sponsor.id)) do
        sponsorship_history
      else
        e -> e
      end
    end)
  end

  def delete(sponsorship_history) when is_struct(sponsorship_history, SponsorshipHistory) do
    Repo.delete(sponsorship_history)
  end

  @spec reached(SponsorshipHistory.t()) :: written_returns
  def reached(sponsorship_history) do
    update(sponsorship_history, %{has_reached: true, reached_at: DateTime.utc_now()})
  end

  @type find_list_cont :: [
          {:has_reached, boolean},
          {:preload, [:sponsor]},
          {:order_by, [{:desc | :asc | :desc_nulls_first, atom}]}
        ]

  @spec find_list(find_list_cont) :: [SponsorshipHistory.t()]
  def find_list(find_list_cont \\ []) do
    has_reached = Keyword.get(find_list_cont, :has_reached)
    preload = Keyword.get(find_list_cont, :preload, [])
    order_by = Keyword.get(find_list_cont, :order_by, desc: :reached_at)

    filter_has_reached =
      (has_reached != nil && dynamic([s], s.has_reached == ^has_reached)) || true

    from(s in SponsorshipHistory,
      where: ^filter_has_reached,
      order_by: ^order_by,
      preload: ^preload
    )
    |> Repo.all()
  end
end
