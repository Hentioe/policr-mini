defmodule PolicrMini.Bot.UserJoinedHandler do
  use PolicrMini.Bot.Handler

  alias PolicrMini.{SchemeBusiness, VerificationBusiness}

  @impl true
  def match?(_message, %{takeovered: false} = state), do: {false, state}

  @impl true
  def match?(%{new_chat_member: nil} = _message, state), do: {false, state}

  # 跳过机器人
  @impl true
  def match?(%{new_chat_member: %{is_bot: true}} = _message, state), do: {false, state}

  @impl true
  def match?(%{new_chat_member: %{id: joined_user_id}} = _message, state),
    do: {joined_user_id != bot_id(), state}

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    case SchemeBusiness.fetch(chat_id) do
      {:ok, scheme} ->
        # TODO: 异步删除服务消息
        Nadia.delete_message(chat_id, message.message_id)
        # TODO: 异步禁言当前用户

        mode = scheme.verification_mode || :image
        entrance = scheme.verification_entrance || :unity
        occasion = scheme.verification_occasion || :private
        seconds = scheme.seconds || 60

        handle(mode, message, state, entrance, occasion, seconds)

      _ ->
        send_message(chat_id, "发生了一些错误，没有读取到本群的验证方案。如果重复出现此问题，请取消机器人的接管状态并通知作者。")

        {:error, state}
    end
  end

  # 统一入口，私聊（当前默认）
  def handle(:image, message, state, :unity, :private, seconds) do
    %{chat: %{id: chat_id}, new_chat_member: new_chat_member} = message

    verification_params = %{
      chat_id: chat_id,
      target_user_id: new_chat_member.id,
      target_user_name: fullname(new_chat_member),
      entrance: :unity,
      seconds: seconds,
      status: :waiting
    }

    # TODO: 异步删除上一条验证提示消息、读取等待验证的人数并根据人数分别响应不同的文本内容
    text = "新成员#{at(new_chat_member)}你好！\n您当前需要完成验证才能发言，验证有效时间只有 #{seconds} 秒。\n过期会被踢出或封禁，请尽快。"

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "点此验证",
            url: "https://t.me/#{bot_username()}?start=verification:v1:#{chat_id}"
          }
        ]
      ]
    }

    with {:ok, verification} <- VerificationBusiness.create(verification_params),
         {:ok, sended_message} <- send_message(chat_id, text, reply_markup: markup),
         {:ok, _} <-
           VerificationBusiness.update(verification, %{message_id: sended_message.message_id}) do
      # TODO: 启动定时任务，读取验证记录并根据结果实施操作
      {:ok, state}
    else
      _ ->
        # TODO: 打印错误
        # TODO: 删除此用户的等待验证记录

        text =
          "发生了一些错误，针对#{at(new_chat_member)}的验证创建失败。\n管理员自行甄别以后可根据决定手动取消限制或封禁。\n如果反复出现此问题，请取消接管状态并通知作者。"

        send_message(chat_id, text)

        {:error, state}
    end
  end
end
