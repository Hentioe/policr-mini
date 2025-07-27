defmodule PolicrMiniWeb.ConsoleV2.API.VerificationView do
  use PolicrMiniWeb, :view
  use PolicrMiniWeb.ConsoleV2.Helpers, :view

  def render("verification.json", %{verification: verification}) do
    %{
      id: verification.id,
      user_id: verification.target_user_id,
      user_full_name: verification.target_user_name,
      status: migrate_status(verification.status),
      source: verification.source,
      duration_secs: verification.seconds,
      inserted_at: verification.inserted_at,
      updated_at: verification.updated_at
    }
  end

  def migrate_status(status) do
    case status do
      :waiting -> :pending
      :passed -> :approved
      :wronged -> :incorrect
      other -> other
    end
  end
end
