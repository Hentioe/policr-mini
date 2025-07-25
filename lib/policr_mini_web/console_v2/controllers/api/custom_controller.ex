defmodule PolicrMiniWeb.ConsoleV2.API.CustomController do
  use PolicrMiniWeb, :controller

  # alias PolicrMini.Chats.CustomKit

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  # todo: 实现增删改查
end
