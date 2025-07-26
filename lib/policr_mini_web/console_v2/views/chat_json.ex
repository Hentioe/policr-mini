defmodule PolicrMiniWeb.ConsoleV2.API.ChatView do
  use PolicrMiniWeb, :console_v2_view

  alias PolicrMini.Stats
  alias PolicrMini.Instances.Chat
  alias PolicrMiniWeb.ConsoleV2.API.{StatsView, CustomView, VerificationView, OperationView}

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

  def render("stats.json", %{stats: stats}) when is_struct(stats, Stats.QueryResult) do
    success(render_one(stats, StatsView, "stats.json"))
  end

  def render("customs.json", %{customs: customs}) when is_list(customs) do
    success(render_many(customs, CustomView, "custom.json"))
  end

  def render("verifications.json", %{verifications: verifications}) when is_list(verifications) do
    success(render_many(verifications, VerificationView, "verification.json"))
  end

  def render("operations.json", %{operations: operations}) when is_list(operations) do
    success(render_many(operations, OperationView, "operation.json"))
  end
end
