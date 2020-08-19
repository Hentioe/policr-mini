defmodule PolicrMiniWeb.Admin.API.ChatController do
  @moduledoc """
  和 Chat 相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.{ChatBusiness, CustomKitBusiness, SchemeBusiness, PermissionBusiness}

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(%{assigns: %{user: user}} = conn, _prams) do
    chats = ChatBusiness.find_list(user.id)

    render(conn, "index.json", %{chats: chats, ending: true})
  end

  def photo(conn, %{"id" => id}) do
    with {:ok, _} <- check_permissions(conn, id),
         {:ok, chat} <- ChatBusiness.get(id) do
      Phoenix.Controller.redirect(conn, to: get_photo_assets(chat.small_photo_id))
    end
  end

  def customs(conn, %{"id" => id}) do
    with {:ok, permissions} <- check_permissions(conn, id),
         {:ok, chat} <- ChatBusiness.get(id) do
      custom_kits = CustomKitBusiness.find_list(id)
      is_enabled = custom_enabled?(id)

      render(conn, "customs.json", %{
        chat: chat,
        custom_kits: custom_kits,
        is_enabled: is_enabled,
        writable: Enum.member?(permissions, :writable)
      })
    end
  end

  @spec custom_enabled?(integer() | String.t()) :: boolean()
  defp custom_enabled?(chat_id) do
    scheme = SchemeBusiness.find(chat_id: chat_id)

    if scheme && scheme.verification_mode == :custom, do: true, else: false
  end

  def scheme(conn, %{"id" => id}) do
    with {:ok, permissions} <- check_permissions(conn, id),
         {:ok, chat} <- ChatBusiness.get(id) do
      scheme = SchemeBusiness.find(chat_id: id)

      render(conn, "scheme.json", %{
        chat: chat,
        scheme: scheme,
        writable: Enum.member?(permissions, :writable)
      })
    end
  end

  def update_scheme(conn, %{"chat_id" => chat_id} = params) do
    with {:ok, _} <- check_permissions(conn, chat_id, [:writable]),
         {:ok, chat} <- ChatBusiness.get(chat_id),
         {:ok, scheme} <- SchemeBusiness.fetch(chat_id),
         {:ok, scheme} <- SchemeBusiness.update(scheme, params) do
      render(conn, "scheme.json", %{chat: chat, scheme: scheme, writable: true})
    end
  end

  def change_takeover(conn, %{"chat_id" => chat_id, "value" => is_takeover} = _params) do
    with {:ok, _} <- check_permissions(conn, chat_id, [:writable]),
         {:ok, chat} <- ChatBusiness.get(chat_id),
         {:ok, _} <- check_takeover_permissions(chat_id, is_takeover),
         {:ok, chat} <- ChatBusiness.update(chat, %{is_take_over: is_takeover}) do
      render(conn, "show.json", %{chat: chat})
    end
  end

  @spec check_takeover_permissions(integer | binary, boolean | binary) ::
          {:ok, [atom]} | {:error, map}
  defp check_takeover_permissions(_chat_id, value) when value in ["false", false], do: {:ok, []}

  defp check_takeover_permissions(chat_id, _value) do
    case Telegex.get_chat_member(chat_id, PolicrMiniBot.id()) do
      {:ok, member} ->
        cond do
          member.status != "administrator" ->
            {:error, %{description: "bot is not an administrator"}}

          member.can_restrict_members == false ->
            {:error, %{description: "bot does not have permission to restrict members"}}

          member.can_delete_messages == false ->
            {:error, %{description: "bot does not have permission to delete messages"}}

          member.can_send_messages == false ->
            {:error, %{description: "bot does not have permission to send messages"}}

          true ->
            {:ok, []}
        end

      {:error, %Telegex.Model.Error{description: description}} ->
        {:error, %{description: description}}

      _ ->
        {:error, %{description: "please try again"}}
    end
  end

  def permissions(conn, %{"chat_id" => chat_id} = _params) do
    with {:ok, perms} <- check_permissions(conn, chat_id),
         {:ok, chat} <- ChatBusiness.get(chat_id) do
      permissions = PermissionBusiness.find_list(chat_id: chat_id, preload: [:user])

      render(conn, "permissions.json", %{
        chat: chat,
        permissions: permissions,
        writable: Enum.member?(perms, :writable)
      })
    end
  end

  def logs(_conn, _params) do
  end

  defp gen_find_list_options(params) do
    to_atom = fn str, default ->
      if str == nil do
        default
      else
        try do
          String.to_existing_atom(str)
        rescue
          _ -> default
        end
      end
    end

    to_integer = fn str, default ->
      if str == nil do
        default
      else
        try do
          String.to_integer(str)
        rescue
          _ -> default
        end
      end
    end

    [
      limit: to_integer.(params["limit"], 35),
      offset: to_integer.(params["offset"], 0),
      order_by: [
        {to_atom.(params["order_direction"], :desc), to_atom.(params["order_by"], :inserted_at)}
      ]
    ]
  end

  def search(conn, %{"keywords" => keywords} = params) do
    options = gen_find_list_options(params)

    with {:ok, _} <- check_sys_permissions(conn) do
      chats = ChatBusiness.search(keywords, options)
      render(conn, "search.json", %{chats: chats})
    end
  end

  def list(conn, params) do
    options = gen_find_list_options(params)

    with {:ok, _} <- check_sys_permissions(conn) do
      chats = ChatBusiness.find_list2(options)
      render(conn, "list.json", %{chats: chats})
    end
  end
end
