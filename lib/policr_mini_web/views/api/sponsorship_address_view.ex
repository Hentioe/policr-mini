defmodule PolicrMiniWeb.API.SponsorshipAddressView do
  @moduledoc """
  前台赞助地址视图数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("sponsorship_address.json", %{sponsorship_address: sponsorship_address}) do
    sponsorship_address
    |> Map.drop([:__meta__, :inserted_at, :updated_at])
    |> Map.from_struct()
  end
end
