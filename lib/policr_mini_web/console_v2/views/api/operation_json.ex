defmodule PolicrMiniWeb.ConsoleV2.API.OperationView do
  use PolicrMiniWeb, :view
  use PolicrMiniWeb.ConsoleV2.Helpers, :view

  alias PolicrMiniWeb.ConsoleV2.API.VerificationView

  def render("operation.json", %{operation: operation}) do
    %{
      id: operation.id,
      action: operation.action,
      role: operation.role,
      verification: render_one(operation.verification, VerificationView, "verification.json"),
      inserted_at: operation.inserted_at,
      updated_at: operation.updated_at
    }
  end
end
