defmodule PolicrMiniWeb.API.ThirdPartyView do
  @moduledoc """
  渲染前台第三方实例数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("third_party.json", %{third_party: third_party}) do
    third_party
    |> Map.drop([:__meta__, :hardware, :inserted_at, :updated_at])
    |> Map.from_struct()
  end

  def render("index.json", %{
        third_parties: third_parties,
        official_index: official_index,
        current_index: current_index
      }) do
    %{
      third_parties: render_many(third_parties, __MODULE__, "third_party.json"),
      official_index: official_index,
      current_index: current_index
    }
  end
end
