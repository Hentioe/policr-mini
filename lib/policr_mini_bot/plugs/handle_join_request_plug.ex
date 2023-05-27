defmodule PolicrMiniBot.HandleJoinRequestPlug do
  @moduledoc false

  use PolicrMiniBot, plug: :preheater

  import PolicrMiniBot.VerificationHelper

  require Logger

  # 忽略未接管
  @impl true
  def call(_update, %{takeovered: false} = state) do
    {:ignored, state}
  end

  # 忽略加入请求为空
  @impl true
  def call(%{chat_join_request: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(update, state) do
    %{from: user, chat: chat, date: date} = update.chat_join_request

    # 私聊验证请求加入的用户
    embarrass_user(:join_request, chat.id, user, date)

    {:ok, state}
  end
end
