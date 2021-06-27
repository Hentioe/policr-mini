defmodule PolicrMiniWeb.Admin.API.SponsorshipHistoryView do
  @moduledoc """
  渲染后台赞助历史数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("sponsorship_history.json", %{sponsorship_history: sponsorship_history}) do
    sponsor =
      render_one(sponsorship_history.sponsor, PolicrMiniWeb.Admin.API.SponsorView, "sponsor.json")

    sponsorship_history
    |> Map.drop([:__meta__, :sponsor])
    |> Map.from_struct()
    |> Map.put(:sponsor, sponsor)
  end

  def render("index.json", %{sponsorship_histories: sponsorship_histories, sponsors: sponsors}) do
    %{
      sponsorship_histories:
        render_many(sponsorship_histories, __MODULE__, "sponsorship_history.json"),
      sponsors: render_many(sponsors, PolicrMiniWeb.Admin.API.SponsorView, "sponsor.json")
    }
  end
end
