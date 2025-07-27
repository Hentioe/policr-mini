defmodule PolicrMiniWeb.ConsoleV2.API.CustomController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Chats
  alias PolicrMini.Chats.CustomKit

  import Canary.Plugs
  import Canada, only: [can?: 2]

  plug :authorize_resource, model: CustomKit, except: [:add]

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  def add(conn, params) do
    with {:write, true} <- {:write, can?(conn, write(params))},
         {:ok, custom} <- Chats.add_custom(params) do
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
