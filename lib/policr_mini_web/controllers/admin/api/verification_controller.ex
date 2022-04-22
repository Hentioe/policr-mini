defmodule PolicrMiniWeb.Admin.API.VerificationController do
  @moduledoc """
  和验证相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{Logger, VerificationBusiness, OperationBusiness}
  alias PolicrMini.Schema.Verification
  alias PolicrMiniBot.Worker

  import PolicrMiniWeb.Helper

  action_fallback(PolicrMiniWeb.API.FallbackController)

  def kill(conn, %{"id" => id, "action" => action} = _params)
      when action in ["manual_ban", "manual_kick"] do
    status = String.to_existing_atom(action)

    with {:ok, veri} <- VerificationBusiness.get(id, preload: [:chat]),
         {:ok, _} <- check_permissions(conn, veri.chat.id, [:writable]),
         {:ok, ok} <- kill_memeber(veri, is_ban: status == :manual_ban) do
      action = if status == :manual_ban, do: :ban, else: :kick

      # 手动终止验证
      :ok = Worker.manual_terminate_validation(veri, status)

      # 添加操作记录（管理员）
      params = %{
        verification_id: veri.id,
        action: action,
        role: :admin
      }

      case OperationBusiness.create(params) do
        {:ok, _} = r ->
          r

        e ->
          Logger.unitized_error("Operation creation", e)
          e
      end

      render(conn, "kick.json", %{ok: ok, verification: veri})
    end
  end

  @type kill_memeber_opts :: [{:is_ban, boolean}]

  # 通过验证记录击杀成员
  @spec kill_memeber(Verification.t(), kill_memeber_opts) :: {:ok, boolean} | {:error, map}
  defp kill_memeber(verification, opts) do
    %{chat: %{id: chat_id}, target_user_id: target_user_id} = verification
    is_ban = Keyword.get(opts, :is_ban)

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
