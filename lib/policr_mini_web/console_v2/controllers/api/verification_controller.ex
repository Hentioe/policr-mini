defmodule PolicrMiniWeb.ConsoleV2.API.VerificationController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.Chats
  alias PolicrMini.Chats.Verification

  require Logger

  import Canary.Plugs

  plug :load_and_authorize_resource, model: Verification

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  @kill_schema %{
    action: [type: :string, in: ~w(manual_ban manual_kick unban)]
  }

  def kill(conn, params) do
    verification = conn.assigns[:verification]

    with {:ok, params} <- Tarams.cast(params, @kill_schema),
         {:ok, _} <- kill_member(verification, params[:action]) do
      # 添加操作记录（不在意添加失败）
      create_operation(verification, params[:action])
      render(conn, "show.json", verification: verification)
    end
  end

  defp kill_member(verification, action) do
    %{chat_id: chat_id, target_user_id: user_id} = verification

    case action do
      "manual_ban" -> ban_member(chat_id, user_id)
      "manual_kick" -> kick_member(chat_id, user_id)
      "unban" -> unban_member(chat_id, user_id)
    end
  end

  defp kick_member(chat_id, user_id) do
    with {:ok, true} <- Telegex.ban_chat_member(chat_id, user_id),
         {:ok, true} <- Telegex.unban_chat_member(chat_id, user_id) do
      {:ok, true}
    else
      err -> err
    end
  end

  defp ban_member(chat_id, user_id) do
    Telegex.ban_chat_member(chat_id, user_id)
  end

  defp unban_member(chat_id, user_id) do
    Telegex.unban_chat_member(chat_id, user_id)
  end

  defp create_operation(verification, action) do
    action =
      case action do
        "manual_ban" -> :ban
        "manual_kick" -> :kick
        "unban" -> :unban
      end

    params = %{
      chat_id: verification.chat_id,
      verification_id: verification.id,
      action: action,
      role: :admin
    }

    case Chats.create_operation(params) do
      {:ok, _} = okr ->
        okr

      {:error, reason} = err ->
        Logger.error("Create operation failed: #{inspect(reason: reason)}")

        err
    end
  end
end
