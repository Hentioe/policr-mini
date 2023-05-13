defmodule PolicrMiniWeb.Admin.API.CustomKitController do
  @moduledoc """
  和 CustomKit 相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{Chats, CustomKitBusiness}

  import PolicrMiniWeb.Helper

  require Logger

  action_fallback PolicrMiniWeb.API.FallbackController

  def add(conn, params) do
    chat_id = params["chat_id"]

    with {:ok, _} <- check_permissions(conn, chat_id, [:writable]),
         {:ok, custom_kit} <- CustomKitBusiness.create(params) do
      render(conn, "custom_kit.json", %{custom_kit: custom_kit})
    end
  end

  def update(conn, %{"id" => id} = params) do
    chat_id = params["chat_id"]

    with {:ok, _} <- check_permissions(conn, chat_id, [:writable]),
         {:ok, custom_kit} <- CustomKitBusiness.get(id),
         {:ok, custom_kit} <- CustomKitBusiness.update(custom_kit, params) do
      render(conn, "custom_kit.json", %{custom_kit: custom_kit})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, custom_kit} <- CustomKitBusiness.get(id),
         {:ok, _} <- check_permissions(conn, custom_kit.chat_id, [:writable]),
         {:ok, custom_kit} <- CustomKitBusiness.delete(custom_kit),
         _ <- check_update_vmethod(custom_kit.chat_id) do
      render(conn, "custom_kit.json", %{custom_kit: custom_kit})
    end
  end

  @spec check_update_vmethod(integer | binary) :: :ok
  defp check_update_vmethod(chat_id) do
    scheme = Chats.find_scheme(chat_id)
    count = Chats.get_custom_kits_count(chat_id)

    case _check_update_vmethod(chat_id, scheme, count) do
      {:ok, _} ->
        :ok

      :ok ->
        :ok

      {:error, reason} ->
        Logger.error(
          "Automatic switching of verification methods failed: #{inspect(reason: reason)}",
          chat_id: chat_id
        )

        :ok
    end
  end

  @spec _check_update_vmethod(integer | binary, map | nil, integer) ::
          :ok | {:ok, map} | {:error, any}
  defp _check_update_vmethod(_chat_id, %{verification_mode: :custom} = scheme, 0 = _count) do
    # 自动更新验证方法为默认值（即空值）
    Chats.update_scheme(scheme, %{verification_mode: :sdf})
  end

  defp _check_update_vmethod(chat_id, nil = _scheme, 0 = _count) do
    # 自动更新验证方法为默认值（即空值）
    Chats.upsert_scheme(chat_id, %{verification_mode: nil})
  end

  defp _check_update_vmethod(_, _, _), do: :ok
end
