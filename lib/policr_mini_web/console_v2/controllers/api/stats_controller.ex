defmodule PolicrMiniWeb.ConsoleV2.API.StatsController do
  use PolicrMiniWeb, :controller

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController
end
