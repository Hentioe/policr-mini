defmodule PolicrMiniWeb.Admin.API.ChatView do
  @moduledoc """
  后台 chat 数据的渲染实现。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{chats: chats, ending: ending}) do
    %{chats: render_many(chats, __MODULE__, "chat.json"), ending: ending}
  end

  def render("show.json", %{chat: chat}) do
    %{chat: render_one(chat, __MODULE__, "chat.json")}
  end

  def render("chat.json", %{chat: chat}) do
    chat |> Map.drop([:__meta__]) |> Map.from_struct()
  end
end
