defmodule PolicrMiniWeb.Admin.API.ChatView do
  @moduledoc """
  渲染后台群组数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{chats: chats, ending: ending}) do
    %{chats: render_many(chats, __MODULE__, "chat.json"), ending: ending}
  end

  def render("customs.json", %{chat: chat, custom_kits: custom_kits, is_enable: is_enable}) do
    chat = render_one(chat, __MODULE__, "chat.json")

    custom_kits =
      render_many(custom_kits, PolicrMiniWeb.Admin.API.CustomKitView, "custom_kit.json")

    %{
      chat: chat,
      custom_kits: custom_kits,
      is_enable: is_enable
    }
  end

  def render("show.json", %{chat: chat}) do
    %{chat: render_one(chat, __MODULE__, "chat.json")}
  end

  def render("chat.json", %{chat: chat}) do
    chat |> Map.drop([:__meta__]) |> Map.from_struct()
  end
end
