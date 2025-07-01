defmodule PolicrMiniWeb.LayoutView do
  use PolicrMiniWeb, :view

  def name do
    Application.get_env(:policr_mini, PolicrMiniBot)[:name] || PolicrMiniBot.name()
  end

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}
end
