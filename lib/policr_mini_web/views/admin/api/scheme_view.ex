defmodule PolicrMiniWeb.Admin.API.SchemeView do
  @moduledoc """
  渲染后台 Scheme 数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("scheme.json", %{scheme: scheme}) do
    scheme |> Map.drop([:__meta__, :chat]) |> Map.from_struct()
  end
end
