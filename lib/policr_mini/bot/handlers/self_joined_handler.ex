defmodule PolicrMini.Bot.SelfJoinedHandler do
  use PolicrMini.Bot.Handler

  alias PolicrMini.Bot.SyncCommander

  @impl true
  def match?(message, state) do
    is_match =
      if new_chat_member = message.new_chat_member do
        %{id: joined_user_id} = new_chat_member
        joined_user_id == PolicrMini.Bot.id()
      else
        false
      end

    {is_match, state}
  end

  @impl true
  def handle(message, state) do
    chat_id = message.chat.id

    # 同步群组和管理员信息
    with {:ok, chat} = SyncCommander.synchronize_chat(chat_id, init: true),
         {:ok, _} <- SyncCommander.synchronize_administrators(chat) do
      Nadia.send_message(
        chat_id,
        "已成功登记本群信息，所有管理员皆可登入后台。\n\n功能启用方法：\n1. 将本机器人提升为管理员\n2. 发送 /sync@#{
          PolicrMini.Bot.username()
        } 指令"
      )
    else
      {:error, _} ->
        Nadia.send_message(chat_id, "出现了一些问题，群组登记失败。请联系作者。")
    end

    {:ok, %{state | done: true}}
  end
end
