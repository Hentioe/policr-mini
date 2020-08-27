defmodule PolicrMiniWeb.LayoutView do
  use PolicrMiniWeb, :view

  def name do
    Application.get_env(:policr_mini, PolicrMiniBot)[:name] || PolicrMiniBot.name()
  end
end
