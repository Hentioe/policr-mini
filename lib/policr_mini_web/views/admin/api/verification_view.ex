defmodule PolicrMiniWeb.Admin.API.VerificationView do
  @moduledoc """
  渲染后台验证数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("kick.json", %{ok: ok, verification: verification}) do
    verification = render_one(verification, __MODULE__, "verification.json")

    %{
      ok: ok,
      verification: verification
    }
  end

  def render("verification.json", %{verification: verification}) do
    verification |> Map.drop([:__meta__, :chat]) |> Map.from_struct()
  end
end
