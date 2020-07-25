defmodule PolicrMiniWeb.API.Admin.ChatController do
  @moduledoc """
  和 chat 相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.ChatBusiness

  def index(%{assigns: %{user: user}} = conn, _prams) do
    chats = ChatBusiness.find_list(user.id)

    render(conn, "index.json", %{chats: chats})
  end

  def show(conn, %{"id" => id}) do
    {:ok, chat} = ChatBusiness.get(String.to_integer(id))

    render(conn, "show.json", %{chat: chat})
  end
end
