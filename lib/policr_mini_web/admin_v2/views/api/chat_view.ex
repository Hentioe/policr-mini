defmodule PolicrMiniWeb.AdminV2.API.ChatView do
  use PolicrMiniWeb, :admin_v2_view

  def render("show.json", %{chat: chat}) do
    success(render_one(chat, __MODULE__, "chat.json"))
  end

  def render("chat.json", %{chat: chat}) do
    %{
      id: chat.id,
      title: chat.title,
      username: chat.username,
      description: chat.description,
      is_take_over: chat.is_take_over,
      left: chat.left,
      created_at: chat.inserted_at
    }
  end
end
