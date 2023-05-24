defmodule PolicrMiniBot.HandleUserJoinedCleanupPlug do
  @moduledoc """
  处理新用户加入。
  """

  # TODO: 修改模块含义并迁移代码。因为设计改动，此 `:message_handler` 已无实际验证处理流程，仅作删除消息之用。

  use PolicrMiniBot, plug: :message_handler

  alias PolicrMini.Chats
  alias PolicrMiniBot.Worker

  require Logger

  @type user :: PolicrMiniBot.Helper.mention_user()

  @doc """
  检查消息中包含的新加入用户是否有效。

  ## 以下情况皆不匹配
  - 群组未接管。

  除此之外包含新成员的消息都将匹配。
  """
  @impl true
  def match(_message, %{takeovered: false} = state), do: {:nomatch, state}
  @impl true
  def match(%{new_chat_members: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(_message, state), do: {:match, state}

  @doc """
  删除进群服务消息。
  """
  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    # TOD0: 将 scheme 的获取放在一个独立的 plug 中，通过状态传递。
    case Chats.find_or_init_scheme(chat_id) do
      {:ok, scheme} ->
        service_message_cleanup = scheme.service_message_cleanup || default!(:smc) || []

        if Enum.member?(service_message_cleanup, :joined) do
          # 删除服务消息。
          Worker.async_delete_message(chat_id, message.message_id)
        end
    end

    {:ok, %{state | done: true, deleted: true}}
  end
end
