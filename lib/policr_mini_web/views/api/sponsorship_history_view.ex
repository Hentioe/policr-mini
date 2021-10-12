defmodule PolicrMiniWeb.API.SponsorshipHistoryView do
  @moduledoc """
  渲染前台赞助历史数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("sponsorship_history.json", %{sponsorship_history: sponsorship_history}) do
    sponsor =
      render_one(sponsorship_history.sponsor, PolicrMiniWeb.API.SponsorView, "sponsor.json")

    sponsorship_history
    |> Map.drop([
      :__meta__,
      :sponsor,
      :creator,
      :inserted_at,
      :updated_at,
      :sponsor_id,
      :has_reached
    ])
    |> Map.from_struct()
    |> Map.put(:sponsor, sponsor)
  end

  def render("added.json", %{sponsorship_history: sponsorship_history, uuid: uuid}) do
    sponsorship_history = render_one(sponsorship_history, __MODULE__, "sponsorship_history.json")

    %{sponsorship_history: sponsorship_history, uuid: uuid}
  end

  def render("index.json", %{
        sponsorship_histories: sponsorship_histories,
        sponsorship_addresses: sponsorship_addresses,
        hints: hints
      }) do
    histories = render_many(sponsorship_histories, __MODULE__, "sponsorship_history.json")

    addresses =
      render_many(
        sponsorship_addresses,
        PolicrMiniWeb.API.SponsorshipAddressView,
        "sponsorship_address.json"
      )

    %{
      sponsorship_histories: histories,
      sponsorship_addresses: addresses,
      hints: hints
    }
  end
end
