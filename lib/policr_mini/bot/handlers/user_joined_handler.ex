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
    %{chat: %{id: chat_id}, from: %{id: from_user_id}} = message

    case SchemeBusiness.fetch(chat_id) do
      {:ok, scheme} ->
        # 异步删除服务消息
        async(fn -> Nadia.delete_message(chat_id, message.message_id) end)
        # 异步限制当前用户
        async(fn -> restrict_chat_member(chat_id, from_user_id) end)

        mode = scheme.verification_mode || :image
        entrance = scheme.verification_entrance || :unity
        occasion = scheme.verification_occasion || :private
        seconds = scheme.seconds || 5

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

    # 异步删除上一条验证提示消息、
    last_verification_message = VerificationBusiness.find_last_unity_waiting(chat_id)

    if last_verification_message,
      do: async(fn -> Nadia.delete_message(chat_id, last_verification_message.message_id) end)

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

    text =
      if waiting_count == 0,
        do:
          "新成员#{at(new_chat_member)}你好！\n您当前需要完成验证才能解除限制，验证有效时间只有 #{seconds} 秒。\n\n过期会被踢出或封禁，请尽快。",
        else:
          "刚来的#{at(new_chat_member)}和另外 #{waiting_count} 个还未验证的新成员，你们好！\n完成验证才能解除限制，验证有效时间不超过 #{
            seconds
          } 秒。\n\n过期会被踢出或封禁，请尽快。"

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
      # 启动定时任务，读取验证记录并根据结果实施操作
      async(
        fn ->
          # 读取验证记录，为 :waiting 状态则实施操作
          # TODO: 根据 scheme 决定执行的动作（当前默认踢出）
          {:ok, latest_verification} = VerificationBusiness.get(verification.id)

          if latest_verification.status == :waiting do
            # 更新状态为超时
            latest_verification |> VerificationBusiness.update(%{status: :timeout})
            # 踢出并解除限制以允许再次加入
            Nadia.kick_chat_member(chat_id, new_chat_member.id)
            async(fn -> Nadia.unban_chat_member(chat_id, new_chat_member.id) end, seconds: 30)

            text = "刚刚#{at(new_chat_member)}超时未验证，已经移出本群。\n\n过 5 分钟后可再次尝试加入。"

            case send_message(chat_id, text) do
              {:ok, sended_timeout_hint_message} ->
                async(
                  fn -> Nadia.delete_message(chat_id, sended_timeout_hint_message.message_id) end,
                  seconds: 15
                )

              _ ->
                # TODO: 记录错误
                nil
            end
          end

          # 更新验证提示
          waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)
          # 已经没有验证，删除验证提示消息
          if waiting_count > 0 do
            first_waiting_verification = VerificationBusiness.find_first_unity_waiting(chat_id)

            target_user = %{
              id: first_waiting_verification.target_user_id,
              fullname: first_waiting_verification.target_user_name
            }

            text =
              if waiting_count == 1,
                do: "新成员#{at(target_user)}你好！\n您还未完成验证，验证有效时间只有 #{seconds} 秒。\n\n过期会被踢出或封禁，请尽快。",
                else:
                  "来了有一会儿的#{at(target_user)}和另外 #{waiting_count} 个还未验证的新成员，你们好！\n完成验证解除限制，验证有效时间不超过 #{
                    seconds
                  } 秒。\n\n过期会被踢出或封禁，请尽快。"

            {:ok, sended_temp_hint_message} = send_message(chat_id, text, reply_markup: markup)

            async(fn -> Nadia.delete_message(chat_id, sended_temp_hint_message.message_id) end,
              seconds: 35
            )
          else
            # 已经没有剩余验证，直接删除上一个验证提示消息
            Nadia.delete_message(chat_id, sended_message.message_id)
          end
        end,
        seconds: seconds
      )

      {:ok, %{state | done: true, deleted: true}}
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
