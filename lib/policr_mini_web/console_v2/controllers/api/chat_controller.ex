defmodule PolicrMiniWeb.ConsoleV2.API.ChatController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Instances.Chat

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  def index(conn, _params) do
    # 迭代生成 10 个群组
    chats =
      for i <- 1..10 do
        %Chat{
          id: i,
          title: "群组#{i}",
          username: "my_chat#{i}",
          description: "群组#{i}的描述",
          is_take_over: i == 1,
          left: rem(i, 2) == 0,
          inserted_at: ~N[2023-10-01 12:00:00]
        }
      end

    render(conn, "index.json", chats: chats)
  end
end
