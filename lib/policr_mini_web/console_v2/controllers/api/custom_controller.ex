defmodule PolicrMiniWeb.ConsoleV2.API.CustomController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Chats

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  def add(conn, params) do
    with {:ok, custom} <- Chats.add_custom(params) do
      render(conn, "show.json", %{custom: custom})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, custom} <- Chats.load_custom(id),
         {:ok, custom} <- Chats.update_custom(custom, params) do
      render(conn, "show.json", %{custom: custom})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, custom} <- Chats.load_custom(id),
         {:ok, custom} <- Chats.delete_custom(custom) do
      render(conn, "show.json", %{custom: custom})
    end
  end
end
