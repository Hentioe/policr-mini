defmodule PolicrMiniWeb.Admin.API.VerificationView do
  @moduledoc """
  渲染后台验证数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("verification.json", %{verification: verification}) do
    verification |> Map.drop([:__meta__, :chat, :message_snapshot]) |> Map.from_struct()
  end
end
