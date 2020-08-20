defmodule PolicrMiniWeb.Admin.API.ChatView do
  @moduledoc """
  渲染后台群组数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{chats: chats, ending: ending}) do
    %{chats: render_many(chats, __MODULE__, "chat.json"), ending: ending}
  end

  def render("customs.json", %{
        chat: chat,
        custom_kits: custom_kits,
        is_enabled: is_enabled,
        writable: writable
      }) do
    chat = render_one(chat, __MODULE__, "chat.json")

    custom_kits =
      render_many(custom_kits, PolicrMiniWeb.Admin.API.CustomKitView, "custom_kit.json")

    %{
      chat: chat,
      custom_kits: custom_kits,
      is_enabled: is_enabled,
      writable: writable
    }
  end

  def render("scheme.json", %{chat: chat, scheme: scheme, writable: writable}) do
    chat = render_one(chat, __MODULE__, "chat.json")
    scheme = render_one(scheme, PolicrMiniWeb.Admin.API.SchemeView, "scheme.json")

    %{
      chat: chat,
      scheme: scheme,
      writable: writable
    }
  end

  def render("permissions.json", %{chat: chat, permissions: permissions, writable: writable}) do
    chat = render_one(chat, __MODULE__, "chat.json")

    permissions =
      render_many(permissions, PolicrMiniWeb.Admin.API.PermissionView, "permission.json")

    %{
      chat: chat,
      permissions: permissions,
      writable: writable
    }
  end

  def render("verifications.json", %{chat: chat, verifications: verifications, writable: writable}) do
    chat = render_one(chat, __MODULE__, "chat.json")

    verifications =
      render_many(verifications, PolicrMiniWeb.Admin.API.VerificationView, "verification.json")

    %{
      chat: chat,
      verifications: verifications,
      writable: writable
    }
  end

  def render("search.json", %{chats: chats}) do
    %{chats: render_many(chats, __MODULE__, "chat.json")}
  end

  def render("list.json", %{chats: chats}) do
    %{chats: render_many(chats, __MODULE__, "chat.json")}
  end

  def render("show.json", %{chat: chat}) do
    %{chat: render_one(chat, __MODULE__, "chat.json")}
  end

  def render("chat.json", %{chat: chat}) do
    chat |> Map.drop([:__meta__]) |> Map.from_struct()
  end
end
