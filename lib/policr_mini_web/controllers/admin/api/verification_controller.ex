defmodule PolicrMiniWeb.Admin.API.VerificationController do
  @moduledoc """
  和验证相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{VerificationBusiness, OperationBusiness}
  alias PolicrMini.Logger

  import PolicrMiniWeb.Helper

  action_fallback(PolicrMiniWeb.API.FallbackController)

  def kick(conn, %{"id" => id, "ban" => ban} = _params) do
    is_ban = ban == "true"

    with {:ok, verification} <- VerificationBusiness.get(id, preload: [:chat]),
         {:ok, _} <- check_permissions(conn, verification.chat.id, [:writable]),
         {:ok, ok} <- kick_by_verification(verification, is_ban: is_ban) do
      action = if is_ban, do: :ban, else: :kick

      # 添加操作记录（管理员）。
      case OperationBusiness.create(%{
             verification_id: verification.id,
             action: action,
             role: :admin
           }) do
        {:ok, _} = r ->
          r

        e ->
          Logger.unitized_error("Operation creation", e)
          e
      end

      render(conn, "kick.json", %{ok: ok, verification: verification})
    end
  end

  @type kick_by_verification_opts :: [{:is_ban, boolean}]

  @spec kick_by_verification(PolicrMini.Schema.Verification.t(), kick_by_verification_opts) ::
          {:ok, boolean} | {:error, map}
  defp kick_by_verification(verification, options) do
    %{chat: %{id: chat_id}, target_user_id: target_user_id} = verification
    is_ban = Keyword.get(options, :is_ban)

    with {:ok, true} <- Telegex.ban_chat_member(chat_id, target_user_id),
         # 此处通过后台页面操作，立即解封
         {:ok, true} <-
           if(is_ban, do: {:ok, true}, else: Telegex.unban_chat_member(chat_id, target_user_id)) do
      {:ok, true}
    else
      {:error, %Telegex.Model.RequestError{}} ->
        {:error, %{description: "please try again"}}

      {:error, %Telegex.Model.Error{description: <<"Bad Request: " <> reason>>}} ->
        {:error, %{description: reason}}

      {:error, %Telegex.Model.Error{description: <<"Forbidden: " <> reason>>}} ->
        {:error, %{description: reason}}

      {:error, %Telegex.Model.Error{description: description}} ->
        {:error, %{description: description}}

      {:ok, false} ->
        {:ok, false}
    end
  end
end
