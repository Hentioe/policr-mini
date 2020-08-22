defmodule PolicrMiniBot.MemberRemovedHandler do
  @moduledoc """
  群成员被移除的处理器。
  """

  use PolicrMiniBot, plug: :handler

  @doc """
  匹配消息中是否包含已被机器人移除的群成员。

  ## 不匹配条件
  - 消息中不包含离开的群成员
  - 消息的发送者不是机器人自己
  - 消息中已离开的群成员是机器人自己
  """
  @impl true
  def match(%{left_chat_member: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(message, state) do
    %{left_chat_member: %{id: lefted_user_id}, from: %{id: from_user_id}} = message
    bot_id = bot_id()

    # 发送者为机器人自己且离开的不是机器人自己即表示被机器人移除
    if from_user_id == bot_id && lefted_user_id != bot_id do
      {:match, state}
    else
      {:nomatch, state}
    end
  end

  @impl true
  def handle(message, state) do
    Cleaner.delete_message(message.chat.id, message.message_id)

    {:ok, state}
  end
end
