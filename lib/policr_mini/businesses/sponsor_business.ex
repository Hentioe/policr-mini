defmodule PolicrMini.SponsorBusiness do
  @moduledoc """
  赞助者的业务功能实现。
  """

  use PolicrMini, business: PolicrMini.Schema.Sponsor

  import Ecto.Query, only: [from: 2]

  @type written_returns :: {:ok, Sponsor.t()} | {:error, Ecto.Changeset.t()}

  @spec create(map) :: written_returns
  def create(params) do
    %Sponsor{uuid: UUID.uuid4()} |> Sponsor.changeset(params) |> Repo.insert()
  end

  @spec update(Sponsor.t(), map) :: written_returns
  def update(sponsor, params) do
    sponsor |> Sponsor.changeset(params) |> Repo.update()
  end

  def delete(sponsor) when is_struct(sponsor, Sponsor) do
    Repo.delete(sponsor)
  end

  @spec find_list(keyword) :: [Sponsor.t()]
  def find_list(_find_list_conts \\ []) do
    from(s in Sponsor, order_by: [desc: s.updated_at])
    |> Repo.all()
  end
end
