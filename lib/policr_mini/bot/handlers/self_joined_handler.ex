defmodule PolicrMini.Bot.SelfJoinedHandler do
  use PolicrMini.Bot.Handler

  alias PolicrMini.Bot.SyncCommander

  @impl true
  def match?(%{new_chat_member: nil} = _message, state), do: {false, state}

  @impl true
  def match?(%{new_chat_member: %{id: joined_user_id}} = _message, state),
    do: {joined_user_id == bot_id(), state}

  @impl true
  def handle(message, state) do
    chat_id = message.chat.id

    # 同步群组和管理员信息
    with {:ok, chat} = SyncCommander.synchronize_chat(chat_id, init: true),
         {:ok, _} <- SyncCommander.synchronize_administrators(chat) do
      {:ok, _} =
        send_message(
          chat_id,
          "已成功登记本群信息，所有管理员皆可登入后台。\n\n功能启用方法：\n1. 将本机器人提升为管理员\n2. 发送 /sync@#{
            PolicrMini.Bot.username()
          } 指令",
          parse_mode: nil
        )
    else
      {:error, _} ->
        send_message(chat_id, "出现了一些问题，群组登记失败。请联系作者。")
    end

    {:ok, %{state | done: true}}
  end
end
