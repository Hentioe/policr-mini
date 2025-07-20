defmodule PolicrMiniWeb.AdminV2.API.ManagementController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Instances.Chat

  def index(conn, _params) do
    chats =
      Enum.map(1..10, fn i ->
        %Chat{
          id: 1_000_000_000_000 + i,
          title: "你好你好你好#{i}",
          username: "username#{i}",
          description: "描述信息 描述信息 描述信息 描述信息 描述信息 #{i}",
          is_take_over: false,
          left: false,
          inserted_at: ~N[2025-07-19 14:00:00]
        }
      end)

    page = 1
    page_size = 10
    chats_total = length(chats)

    render(conn, "index.json",
      chats: chats,
      page: page,
      page_size: page_size,
      chats_total: chats_total
    )
  end
end
