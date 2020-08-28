defmodule PolicrMiniWeb.Admin.API.OperationView do
  @moduledoc """
  渲染后台操作数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("operation.json", %{operation: operation}) do
    verification =
      render_one(
        operation.verification,
        PolicrMiniWeb.Admin.API.VerificationView,
        "verification.json"
      )

    operation = %{operation | verification: verification}

    operation |> Map.drop([:__meta__]) |> Map.from_struct()
  end
end
