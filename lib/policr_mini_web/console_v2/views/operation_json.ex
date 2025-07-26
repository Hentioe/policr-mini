defmodule PolicrMiniWeb.ConsoleV2.API.OperationView do
  use PolicrMiniWeb, :console_v2_view

  alias PolicrMiniWeb.ConsoleV2.API.VerificationView

  def render("index.json", %{operations: operations}) do
    %{data: render_many(operations, __MODULE__, "operation.json")}
  end

  def render("show.json", %{operation: operation}) do
    %{data: render_one(operation, __MODULE__, "operation.json")}
  end

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
