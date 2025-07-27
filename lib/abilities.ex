defmodule Abilities do
  @moduledoc false

  alias PolicrMini.Uses
  alias PolicrMini.Schema.User
  alias PolicrMini.Instances.Chat

  defimpl Canada.Can, for: User do
    # 对应 PolicrMiniWeb.ConsoleV2.API.ChatController 中的路由函数，需可读权限
    @chat_accessible [:stats, :scheme, :customs, :verifications, :operations]

    @impl true
    def can?(%User{id: user_id} , action, %Chat{id: chat_id}) when action in @chat_accessible do
      if permission = Uses.get_permission(chat_id, user_id) do
        permission.readable || permission.owner
      else
        false
      end
    end

    @impl true
    def can?(%User{}, _action, _), do: false
  end
end
