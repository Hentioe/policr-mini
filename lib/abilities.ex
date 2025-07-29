defmodule Abilities do
  @moduledoc false

  alias PolicrMini.Uses
  alias PolicrMini.Schema.User

  require Logger

  defimpl Canada.Can, for: Plug.Conn do
    alias Plug.Conn

    # 用请求参数中的 chat_id 进行权限检查，通常用于手动调用 can? write(resource)
    @impl true
    def can?(%Conn{assigns: %{user: user}}, :write, %{"chat_id" => chat_id}) do
      if permission = Uses.get_permission(chat_id, user.id) do
        permission.writable || permission.owner
      else
        false
      end
    end
  end

  defimpl Canada.Can, for: User do
    alias PolicrMini.Instances.Chat
    alias PolicrMini.Chats.Scheme
    alias PolicrMini.Chats.CustomKit
    alias PolicrMini.Chats.Verification

    # 用户对群组的访问权限检查
    @impl true
    def can?(%User{id: user_id}, action, %Chat{id: chat_id})
        when action in [:stats, :scheme, :customs, :verifications, :operations] do
      if permission = Uses.get_permission(chat_id, user_id) do
        permission.readable || permission.owner
      else
        false
      end
    end

    # 用户对自定义条目写入操作的权限检查
    @impl true
    def can?(%User{id: user_id}, action, %CustomKit{chat_id: chat_id})
        when action in [:add, :update, :delete] do
      if permission = Uses.get_permission(chat_id, user_id) do
        permission.writable || permission.owner
      else
        false
      end
    end

    def can?(%User{id: user_id}, action, %Scheme{chat_id: chat_id}) when action in [:update] do
      # 用户对方案条目写入操作的权限检查
      if permission = Uses.get_permission(chat_id, user_id) do
        permission.writable || permission.owner
      else
        false
      end
    end

    def can?(%User{id: user_id}, action, %Verification{chat_id: chat_id})
        when action in [:kill] do
      # 用户对验证条目写入操作的权限检查
      if permission = Uses.get_permission(chat_id, user_id) do
        permission.writable || permission.owner
      else
        false
      end
    end

    @impl true
    def can?(%User{}, action, subject) do
      Logger.warning("Unknown user action: #{inspect(action)} on subject: #{inspect(subject)}")

      false
    end
  end
end
