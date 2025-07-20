defmodule PolicrMiniWeb.AdminV2.API.ManagementView do
  use PolicrMiniWeb, :admin_v2_view

  def render("index.json", %{
        chats: chats,
        page: page,
        page_size: page_size,
        chats_total: chats_total
      }) do
    chats = render_many(chats, PolicrMiniWeb.AdminV2.API.ChatView, "chat.json")

    success(%{
      chats: chats,
      page: page,
      page_size: page_size,
      chats_total: chats_total
    })
  end
end
