defmodule PolicrMini.Bot.UserJoinedHandler do
  @moduledoc """
  新用户加入处理模块。
  """
  use PolicrMini.Bot.Handler

  alias PolicrMini.Schema.{Verification, Scheme}
  alias PolicrMini.{SchemeBusiness, VerificationBusiness}
  alias PolicrMini.Bot.VerificationCallbacker

  @spec countdown :: integer()
  @doc """
  获取倒计时。
  当前的实现会根据运行模式返回不同的值。
  """
  def countdown do
    if PolicrMini.mix_env() == :dev, do: 15, else: 60 * 5
  end

  @spec allow_join_again_seconds :: integer()
  @doc """
  获取允许重新加入时长。
  当前的实现会根据运行模式返回不同的值。
  """
  def allow_join_again_seconds do
    if PolicrMini.mix_env() == :dev, do: 15, else: 60 * 2
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
  1. 读取验证方案，根据方案选择验证发送方式
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

        mode = scheme.verification_mode || default!(:vmode)
        entrance = scheme.verification_entrance || default!(:ventrance)
        occasion = scheme.verification_occasion || default!(:voccasion)
        seconds = scheme.seconds || countdown()

        handle(mode, entrance, occasion, seconds, message, state)

      _ ->
        send_message(chat_id, t("errors.scheme_fetch_failed"))

        {:error, state}
    end
  end

  @doc """
  算术验证 + 统一入口 + 私聊方案的细节实现。
  主要进行以下大致流程，按先后顺序：
  1. 删除上一条统一验证入口消息
  1. 读取等待验证的人，根据人数分别响应不同的文本内容
  1. 启动定时任务，读取验证记录并根据结果实施操作
  """
  def handle(:arithmetic, :unity, :private, seconds, message, state) do
    %{chat: %{id: chat_id}, new_chat_member: new_chat_member} = message

    # 获取上一条等待验证记录
    last_verification = VerificationBusiness.find_last_unity_waiting(chat_id)

    if last_verification,
      do: async(fn -> Nadia.delete_message(chat_id, last_verification.message_id) end)

    verification_params = %{
      chat_id: chat_id,
      target_user_id: new_chat_member.id,
      target_user_name: fullname(new_chat_member),
      entrance: :unity,
      seconds: seconds,
      status: :waiting
    }

    with {:ok, verification} <- VerificationBusiness.fetch(verification_params),
         {text, markup} <- make_verification_message(verification, seconds),
         {:ok, reminder_message} <- send_message(chat_id, text, reply_markup: markup),
         {:ok, _} <-
           VerificationBusiness.update(verification, %{message_id: reminder_message.message_id}) do
      # 启动定时任务，读取验证记录并根据结果实施操作
      # TODO: 当前的实现没有检查在验证期间同一个用户重复加入的情况
      {:ok, scheme} = SchemeBusiness.fetch(chat_id)

      start_scheduled_task(
        verification,
        scheme,
        seconds,
        reminder_message.message_id
      )

      {:ok, %{state | done: true, deleted: true}}
    else
      _ ->
        # TODO: 打印错误
        # TODO: 删除此用户的等待验证记录

        text = t("errors.verification_created_failed", %{mentioned_user: at(new_chat_member)})
        send_message(chat_id, text)

        {:error, state}
    end
  end

  @spec make_verification_message(Verification.t(), integer()) ::
          {String.t(), InlineKeyboardMarkup.t()}
  @doc """
  生成验证消息。
  注意：此函数需要在验证记录创建以后调用，否则会出现不正确的等待验证人数。
  因为当前默认统一验证入口的关系，此函数生成的验证入口而不是验证消息。
  """
  def make_verification_message(%Verification{} = verification, seconds) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} =
      verification

    new_chat_member = %{id: target_user_id, fullname: target_user_name}

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

    make_unity_message(chat_id, new_chat_member, waiting_count, seconds)
  end

  @spec make_unity_message(integer(), map(), integer(), integer()) ::
          {String.t(), InlineKeyboardMarkup.t()}
  @doc """
  生成统一验证入口消息。
  参数 `user` 需要满足 `PolicrMini.Bot.Helper.fullname/1` 函数子句的匹配，表示被提及的用户。
  """
  def make_unity_message(chat_id, user, waiting_count, seconds)
      when is_integer(chat_id) and is_map(user) and is_integer(waiting_count) and
             is_integer(seconds) do
    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    text =
      if waiting_count == 1,
        do: t("verification.unity.single_waiting", %{mentioned_user: at(user), seconds: seconds}),
        else:
          t("verification.unity.multiple_waiting", %{
            mentioned_user: at(user),
            remaining_count: waiting_count - 1,
            seconds: seconds
          })

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: t("buttons.verification.click_here"),
            url: "https://t.me/#{bot_username()}?start=verification_v1_#{chat_id}"
          }
        ]
      ]
    }

    {text, markup}
  end

  @spec start_scheduled_task(Verification.t(), Scheme.t(), integer(), integer()) :: :ok
  @doc """
  启动定时任务处理验证超时。
  # TODO: 根据 scheme 决定执行的动作
  """
  def start_scheduled_task(
        %Verification{} = verification,
        %Scheme{} = scheme,
        seconds,
        reminder_message_id
      )
      when is_integer(seconds) and is_integer(reminder_message_id) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} =
      verification

    target_user = %{id: target_user_id, fullname: target_user_name}

    task = fn ->
      # 读取验证记录，为等待状态则实施操作
      {:ok, latest_verification} = VerificationBusiness.get(verification.id)

      if latest_verification.status == :waiting do
        # 更新状态为超时
        latest_verification |> VerificationBusiness.update(%{status: :timeout})
        # TODO: 此处需要根据 scheme
        # 实施操作（踢出）
        kick(chat_id, target_user, :timeout)
        # 解除限制以允许再次加入
        async(fn -> Nadia.unban_chat_member(chat_id, target_user_id) end,
          seconds: allow_join_again_seconds()
        )
      end

      # TODO: 此处需要根据 scheme
      # 如果还存在多条验证，更新入口消息

      waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

      if waiting_count == 0 do
        # 已经没有剩余验证，直接删除上一个提醒消息
        Nadia.delete_message(chat_id, reminder_message_id)
      else
        # 如果还存在多条验证，更新入口消息
        max_seconds = scheme.seconds || default!(:vseconds)

        VerificationCallbacker.update_unity_verification_message(
          chat_id,
          waiting_count,
          max_seconds
        )
      end
    end

    async(task, seconds: seconds)
  end

  @type reason :: :wronged | :timeout

  @spec kick(integer(), map(), reason()) :: :ok | {:error, Nadia.Model.Error.t()}
  def kick(chat_id, user, reason) when is_integer(chat_id) and is_map(user) and is_atom(reason) do
    # 踢出用户
    Nadia.kick_chat_member(chat_id, user.id)
    # 解除限制以允许再次加入
    async(fn -> Nadia.unban_chat_member(chat_id, user.id) end,
      seconds: allow_join_again_seconds()
    )

    time_text =
      if allow_join_again_seconds() < 60,
        do: "#{allow_join_again_seconds()} #{t("units.sec")}",
        else: "#{to_string(allow_join_again_seconds() / 60)} #{t("units.min")}"

    text =
      case reason do
        :timeout ->
          t("verification.timeout.kick.notice", %{mentioned_user: at(user), time_text: time_text})

        :wronged ->
          t("verification.wronged.kick.notice", %{mentioned_user: at(user), time_text: time_text})
      end

    case send_message(chat_id, text) do
      {:ok, sended_message} ->
        delete_message(chat_id, sended_message.message_id, delay_seconds: 8)

        :ok

      e ->
        # TODO: 记录错误
        e
    end
  end
end
