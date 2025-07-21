defmodule PolicrMiniWeb.AdminV2.API.ChatController do
  use PolicrMiniWeb, :controller

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  alias PolicrMini.Instances.Chat

  defdelegate synchronize_chat(chat_id), to: PolicrMiniBot.RespSyncChain

  def sync(conn, %{"id" => chat_id}) do
    with {:ok, chat} <- synchronize_chat(chat_id) do
      render(conn, "show.json", %{chat: chat})
    end
  end

  def leave(conn, %{"id" => chat_id} = _params) do
    with {:ok, chat} <- Chat.get(chat_id),
         {:ok, true} <- Telegex.leave_chat(chat_id) do
      render(conn, "show.json", chat: chat)
    end
  end
end
