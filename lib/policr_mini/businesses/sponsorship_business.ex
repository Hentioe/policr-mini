defmodule PolicrMini.SponsorshipHistoryBusiness do
  @moduledoc """
  赞助历史的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.SponsorshipHistory

  import Ecto.Query, only: [from: 2, dynamic: 2]

  @type written_returns :: {:ok, SponsorshipHistory.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map) :: written_returns
  def create(params) do
    %SponsorshipHistory{} |> SponsorshipHistory.changeset(params) |> Repo.insert()
  end

  @spec update(SponsorshipHistory.t(), map) :: written_returns
  def update(sponsorship_history, params) do
    sponsorship_history |> SponsorshipHistory.changeset(params) |> Repo.update()
  end

  def delete(sponsorship_history) when is_struct(sponsorship_history, SponsorshipHistory) do
    Repo.delete(sponsorship_history)
  end

  @spec reached(SponsorshipHistory.t()) :: written_returns
  def reached(sponsorship_history) do
    update(sponsorship_history, %{has_reached: true, reached_at: DateTime.utc_now()})
  end

  @type find_list_cont :: [{:has_reached, boolean}]

  @spec find_list(find_list_cont) :: [SponsorshipHistory.t()]
  def find_list(find_list_cont \\ []) do
    has_reached = Keyword.get(find_list_cont, :has_reached)

    filter_has_reached =
      (has_reached != nil && dynamic([s], s.has_reached == ^has_reached)) || true

    from(s in SponsorshipHistory,
      where: ^filter_has_reached,
      order_by: [desc: s.reached_at]
    )
    |> Repo.all()
  end
end
