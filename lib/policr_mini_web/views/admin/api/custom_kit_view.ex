defmodule PolicrMiniWeb.Admin.API.CustomKitView do
  @moduledoc """
  渲染后台自定义套件数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("custom_kit.json", %{custom_kit: custom_kit}) do
    custom_kit |> Map.drop([:__meta__, :chat]) |> Map.from_struct()
  end
end
