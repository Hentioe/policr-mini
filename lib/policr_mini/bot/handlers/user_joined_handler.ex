defmodule PolicrMini.Bot.UserJoinedHandler do
  @moduledoc """
  新用户加入处理模块。
  """
  use PolicrMini.Bot.Handler

  alias PolicrMini.{SchemeBusiness, VerificationBusiness}

  if Mix.env() == :dev do
    @default_countdown 600
    @allow_join_again_seconds 15
  else
    @allow_join_again_seconds 60 * 5
    @default_countdown 120
  end

  @doc """
  未接管状态，不匹配。
  """
  @impl true
  def match?(_message, %{takeovered: false} = state), do: {false, state}

  @doc """
  消息中不包含新成员，不匹配。
  """
  @impl true
  def match?(%{new_chat_member: nil} = _message, state), do: {false, state}

  @doc """
  消息中的新成员类型是机器人，不匹配。
  """
  @impl true
  def match?(%{new_chat_member: %{is_bot: true}} = _message, state), do: {false, state}

  @doc """
  其余情况皆匹配。
  """
  @impl true
  def match?(_message, state), do: {true, state}

  @doc """
  新成员处理函数。
  主要进行以下大致流程，按先后顺序：
  1. 删除服务消息
  1. 限制新成员权限
  1. 读取验证方案，根据方案发送验证入口消息或验证消息
  """
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
        seconds = scheme.seconds || @default_countdown

        handle(mode, message, state, entrance, occasion, seconds)

      _ ->
        send_message(chat_id, "发生了一些错误，没有读取到本群的验证方案。如果重复出现此问题，请取消机器人的接管状态并通知作者。")

        {:error, state}
    end
  end

  @doc """
  统一入口 + 私聊（当前默认）方案的细节实现。
  主要进行以下大致流程，按先后顺序：
  1. 删除上一条统一验证入口消息
  1. 读取等待验证的人，根据人数分别响应不同的文本内容
  1. 启动定时任务，读取验证记录并根据结果实施操作
  """
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

    # 异步删除上一条验证提示消息
    last_verification_message = VerificationBusiness.find_last_unity_waiting(chat_id)

    if last_verification_message,
      do: async(fn -> Nadia.delete_message(chat_id, last_verification_message.message_id) end)

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

    text =
      if waiting_count == 0,
        do:
          "新成员#{at(new_chat_member)}你好！\n\n您当前需要完成验证才能解除限制，验证有效时间只有 #{seconds} 秒。\n过期会被踢出或封禁，请尽快。",
        else:
          "刚来的#{at(new_chat_member)}和另外 #{waiting_count} 个还未验证的新成员，你们好！\n\n请主动完成验证解除限制，验证有效时间不超过 #{
            seconds
          } 秒。\n过期会被踢出或封禁，请尽快。"

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "点此验证",
            url: "https://t.me/#{bot_username()}?start=verification_v1_#{chat_id}"
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
            # 实施操作（踢出）
            Nadia.kick_chat_member(chat_id, new_chat_member.id)
            # 解除限制以允许再次加入
            async(fn -> Nadia.unban_chat_member(chat_id, new_chat_member.id) end,
              seconds: @allow_join_again_seconds
            )

            time_text =
              if @allow_join_again_seconds < 60,
                do: "#{@allow_join_again_seconds} 秒",
                else: "#{to_string(@allow_join_again_seconds / 60)} 分钟"

            text = "刚刚#{at(new_chat_member)}超时未验证，已经移出本群。\n\n过 #{time_text}后可再次尝试加入。"

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

          waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

          if waiting_count > 0 do
            # 发送新的验证提醒消息
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
          "发生了一些错误，针对#{at(new_chat_member)}的验证创建失败。建议管理员自行甄再决定手动取消限制或封禁。\n\n如果反复出现此问题，请取消接管状态并通知作者。"

        send_message(chat_id, text)

        {:error, state}
    end
  end

  @type reason :: :wronged | :timeout

  @spec kick(integer(), map(), reason()) :: :ok | {:error, Nadia.Model.Error.t()}
  def kick(chat_id, user, reason) when is_integer(chat_id) and is_map(user) and is_atom(reason) do
    # 踢出用户
    Nadia.kick_chat_member(chat_id, user.id)
    # 解除限制以允许再次加入
    async(fn -> Nadia.unban_chat_member(chat_id, user.id) end,
      seconds: @allow_join_again_seconds
    )

    time_text =
      if @allow_join_again_seconds < 60,
        do: "#{@allow_join_again_seconds} 秒",
        else: "#{to_string(@allow_join_again_seconds / 60)} 分钟"

    text =
      case reason do
        :timeout ->
          "刚刚#{at(user)}超时未验证，已经移出本群。\n\n过 #{time_text}后可再次尝试加入。"

        :wronged ->
          "刚刚#{at(user)}验证错误，已经移出本群。\n\n过 #{time_text}后可再次尝试加入。"
      end

    case send_message(chat_id, text) do
      {:ok, sended_message} ->
        async(
          fn -> Nadia.delete_message(chat_id, sended_message.message_id) end,
          seconds: 15
        )

        :ok

      e ->
        e
    end
  end
end
