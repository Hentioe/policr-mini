defmodule PolicrMiniWeb.Admin.API.ThirdPartyView do
  @moduledoc """
  渲染后台第三方实例数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("third_party.json", %{third_party: third_party}) do
    third_party |> Map.drop([:__meta__]) |> Map.from_struct()
  end

  def render("index.json", %{third_parties: third_parties}) do
    %{
      third_parties: render_many(third_parties, __MODULE__, "third_party.json")
    }
  end
end
