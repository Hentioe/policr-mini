defmodule PolicrMiniBot.UserLeftedHandler do
  @moduledoc """
  用户离开群组的处理器。
  """

  use PolicrMiniBot, plug: :handler

  alias PolicrMini.PermissionBusiness

  @doc """
  匹配消息中是否包含离开群组的用户。

  如果离开群组的用户是机器人自己，则不匹配。否则皆匹配。
  """
  @impl true
  def match(%{left_chat_member: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(%{left_chat_member: %{id: lefted_user_id}} = _message, state) do
    if lefted_user_id == bot_id() do
      {:nomatch, state}
    else
      {:match, state}
    end
  end

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, left_chat_member: %{id: user_id}} = message

    # 如果是管理员（非群主）则删除权限记录
    if perm = PermissionBusiness.find(chat_id, user_id) do
      unless perm.tg_is_owner do
        PermissionBusiness.delete(chat_id, user_id)
      end
    end

    {:ok, %{state | done: true}}
  end
end
