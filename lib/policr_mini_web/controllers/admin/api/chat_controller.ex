defmodule PolicrMiniWeb.Admin.API.ChatController do
  @moduledoc """
  和 Chat 相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{ChatBusiness, CustomKitBusiness, SchemeBusiness}

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(%{assigns: %{user: user}} = conn, _prams) do
    chats = ChatBusiness.find_list(user.id)

    render(conn, "index.json", %{chats: chats, ending: true})
  end

  def photo(conn, %{"id" => id}) do
    with {:ok, chat} <- ChatBusiness.get(id),
         {:ok, %{file_path: file_path}} <- Telegex.get_file(chat.small_photo_id) do
      file_url = "https://api.telegram.org/file/bot#{Telegex.Config.token()}/#{file_path}"

      Phoenix.Controller.redirect(conn, external: file_url)
    else
      _ ->
        Phoenix.Controller.redirect(conn, to: "/images/telegram-x128.png")
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, chat} <- ChatBusiness.get(id) do
      render(conn, "show.json", %{chat: chat})
    end
  end

  def customs(conn, %{"id" => id}) do
    scheme = SchemeBusiness.find(chat_id: id)
    is_enable = if scheme && scheme.verification_mode == :custom, do: true, else: false

    with {:ok, chat} <- ChatBusiness.get(id),
         custom_kits <- CustomKitBusiness.find_list(id) do
      render(conn, "customs.json", %{
        chat: chat,
        custom_kits: custom_kits,
        is_enable: is_enable
      })
    end
  end
end
