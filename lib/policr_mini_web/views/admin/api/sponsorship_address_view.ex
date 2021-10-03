defmodule PolicrMiniWeb.Admin.API.SponsorshipAddressView do
  @moduledoc """
  赞助地址的数据视图。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("sponsorship_address.json", %{sponsorship_address: sponsorship_address}) do
    sponsorship_address |> Map.drop([:__meta__]) |> Map.from_struct()
  end

  def render("index.json", %{sponsorship_addresses: sponsorship_addresses}) do
    %{
      sponsorship_addresses:
        render_many(sponsorship_addresses, __MODULE__, "sponsorship_address.json")
    }
  end
end
