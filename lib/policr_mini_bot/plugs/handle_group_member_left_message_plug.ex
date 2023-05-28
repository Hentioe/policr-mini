defmodule PolicrMiniBot.HandleGroupMemberLeftMessagePlug do
  @moduledoc false

  use PolicrMiniBot, plug: :message_handler

  alias PolicrMini.Chats
  alias PolicrMiniBot.Worker

  require Logger

  # 忽略未接管的群
  @impl true
  def match(_message, %{takeovered: false} = state), do: {:nomatch, state}

  # 忽略离开成员数据为空
  @impl true
  def match(%{left_chat_member: left_chat_member} = _message, state)
      when is_nil(left_chat_member) do
    {:nomatch, state}
  end

  @impl true
  def match(_message, state), do: {:match, state}

  @impl true
  def handle(%{chat: chat, message_id: message_id} = _message, state) do
    state = action(state, :delete_left_message)

    # TOD0: 将 scheme 的获取放在一个独立的 plug 中，通过状态传递。
    # 检测并删除服务消息。
    scheme = Chats.find_or_init_scheme!(chat.id)
    enabled_cleanup = scheme.service_message_cleanup || default!(:smc) || []

    if Enum.member?(enabled_cleanup, :lefted) do
      Logger.debug(
        "Deleting member left message: #{inspect(chat_id: chat.id, message_id: message_id)}"
      )

      # 删除服务消息。
      Worker.async_delete_message(chat.id, message_id)

      {:ok, %{state | deleted: true}}
    else
      {:ok, state}
    end
  end
end
