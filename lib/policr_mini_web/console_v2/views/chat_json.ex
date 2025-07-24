defmodule PolicrMiniWeb.ConsoleV2.API.ChatView do
  use PolicrMiniWeb, :console_v2_view

  alias PolicrMini.Instances.Chat

  def render("index.json", %{chats: chats}) when is_list(chats) do
    success(render_many(chats, __MODULE__, "chat.json"))
  end

  def render("chat.json", %{chat: chat}) when is_struct(chat, Chat) do
    %{
      id: chat.id,
      title: chat.title,
      username: chat.username,
      description: chat.description,
      big_photo_id: chat.big_photo_id,
      taken_over: chat.is_take_over,
      left: chat.left,
      inserted_at: chat.inserted_at
    }
  end
end
