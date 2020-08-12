defmodule PolicrMiniBot.UserJoinedHandler do
  @moduledoc """
  处理新用户加入。
  """

  use PolicrMiniBot, plug: :handler

  alias PolicrMini.Logger

  alias PolicrMini.Schemas.{Verification, Scheme}
  alias PolicrMini.{SchemeBusiness, VerificationBusiness}
  alias PolicrMiniBot.VerificationCaller

  # 过期时间：15 分钟
  @expired_seconds 60 * 15

  @spec countdown :: integer()
  @doc """
  获取倒计时。
  当前的实现会根据运行模式返回不同的值。
  """
  def countdown do
    if PolicrMini.mix_env() == :dev, do: 30 * 3, else: 60 * 5
  end

  @doc """
  获取允许重新加入时长。
  当前的实现会根据运行模式返回不同的值。
  """
  @spec allow_join_again_seconds :: integer()
  def allow_join_again_seconds do
    if PolicrMini.mix_env() == :dev, do: 15, else: 60 * 2
  end

  @doc """
  检查消息中包含的新加入用户是否有效。

  ## 以下情况皆不匹配
  - 群组未接管
  - 拉人或进群的是管理员
  - 拉人或进群的是机器人

  除此之外包含新成员的消息都将匹配。
  """
  @impl true
  def match(_message, %{takeovered: false} = state), do: {:nomatch, state}
  @impl true
  def match(%{new_chat_members: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(_message, %{from_admin: true} = state), do: {:nomatch, state}
  @impl true
  def match(%{new_chat_members: [%{is_bot: true}]} = _message, state), do: {:nomatch, state}
  @impl true
  def match(_message, state), do: {:match, state}

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, new_chat_members: new_chat_members} = message

    case SchemeBusiness.fetch(chat_id) do
      {:ok, scheme} ->
        # 异步删除服务消息
        Cleaner.delete_message(chat_id, message.message_id)
        Enum.each(new_chat_members, &handle_one(&1, scheme, message, state))

        {:ok, %{state | done: true, deleted: true}}

      e ->
        Logger.unitized_error("Verification scheme fetching", chat_id: chat_id, returns: e)

        send_message(chat_id, t("errors.scheme_fetch_failed"))

        {:error, state}
    end
  end

  # 忽略 bot 类型的用户。
  defp handle_one(%{is_bot: true} = _new_chat_member, _scheme, _message, state) do
    {:ignored, state}
  end

  # 处理单个新成员的加入。
  defp handle_one(new_chat_member, scheme, message, state) do
    %{chat: %{id: chat_id}, date: date} = message

    joined_datetime =
      case date |> DateTime.from_unix() do
        {:ok, datetime} -> datetime
        _ -> DateTime.utc_now()
      end

    entrance = scheme.verification_entrance || default!(:ventrance)
    mode = scheme.verification_mode || default!(:vmode)
    occasion = scheme.verification_occasion || default!(:voccasion)
    seconds = scheme.seconds || countdown()

    if DateTime.diff(DateTime.utc_now(), joined_datetime) >= @expired_seconds do
      # 处理过期验证
      handle_expired(entrance, message, state)
    else
      # 异步限制新用户
      async(fn -> restrict_chat_member(chat_id, new_chat_member.id) end)

      handle_it(mode, entrance, occasion, seconds, message, state)
    end
  end

  @doc """
  处理过期验证。
  当前仅限制用户，并不发送验证消息。
  """
  @spec handle_expired(atom(), Message.t(), State.t()) :: {:error, State.t()} | {:ok, State.t()}
  def handle_expired(entrance, message, state) do
    %{chat: %{id: chat_id}, new_chat_members: [new_chat_member]} = message

    verification_params = %{
      chat_id: chat_id,
      target_user_id: new_chat_member.id,
      target_user_name: fullname(new_chat_member),
      target_user_language_code: new_chat_member.language_code,
      entrance: entrance,
      seconds: 0,
      status: :expired
    }

    case VerificationBusiness.fetch(verification_params) do
      {:ok, _} ->
        # 异步限制新用户
        async(fn -> restrict_chat_member(chat_id, new_chat_member.id) end)

        {:ok, state}

      e ->
        Logger.unitized_error("Verification acquisition",
          chat_id: chat_id,
          user_id: new_chat_member.id,
          returns: e
        )

        {:error, state}
    end
  end

  @doc """
  统一入口 + 私聊方案的细节实现。
  """
  def handle_it(_, :unity, :private, seconds, message, state) do
    %{chat: %{id: chat_id}, new_chat_members: [new_chat_member]} = message

    verification_params = %{
      chat_id: chat_id,
      target_user_id: new_chat_member.id,
      target_user_name: fullname(new_chat_member),
      target_user_language_code: new_chat_member.language_code,
      entrance: :unity,
      seconds: seconds,
      status: :waiting
    }

    with {:ok, verification} <- VerificationBusiness.fetch(verification_params),
         {text, markup} <- make_verify_content(verification, seconds),
         {:ok, reminder_message} <-
           Cleaner.send_verification_message(chat_id, text,
             reply_markup: markup,
             parse_mode: "MarkdownV2ToHTML"
           ),
         {:ok, _} <-
           VerificationBusiness.update(verification, %{message_id: reminder_message.message_id}),
         {:ok, scheme} <- SchemeBusiness.fetch(chat_id) do
      # 启动定时任务，读取验证记录并根据结果实施操作
      start_timed_task(
        verification,
        scheme,
        seconds,
        reminder_message.message_id
      )

      {:ok, %{state | done: true, deleted: true}}
    else
      e ->
        Logger.unitized_error("Verification entrance creation", chat_id: chat_id, returns: e)

        text =
          t("errors.verification_created_failed", %{mentioned_user: mention(new_chat_member)})

        send_message(chat_id, text)

        {:error, state}
    end
  end

  @doc """
  生成验证消息。

  注意：此函数需要在验证记录创建以后调用，否则会出现不正确的等待验证人数。
  因为当前默认统一验证入口的关系，此函数生成的是入口消息而不是验证消息。
  """
  @spec make_verify_content(Verification.t(), integer()) ::
          {String.t(), InlineKeyboardMarkup.t()}
  def make_verify_content(%Verification{} = verification, seconds) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} =
      verification

    new_chat_member = %{id: target_user_id, fullname: target_user_name}

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

    make_unity_content(chat_id, new_chat_member, waiting_count, seconds)
  end

  @doc """
  生成统一验证入口消息。

  参数 `user` 需要满足 `PolicrMiniBot.Helper.fullname/1` 函数子句的匹配。
  """
  @spec make_unity_content(integer(), map(), integer(), integer()) ::
          {String.t(), InlineKeyboardMarkup.t()}
  def make_unity_content(chat_id, user, waiting_count, seconds) do
    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    text =
      if waiting_count == 1,
        do:
          t("verification.unity.single_waiting", %{
            mentioned_user: mention(user, anonymization: false, mosaic: true),
            seconds: seconds
          }),
        else:
          t("verification.unity.multiple_waiting", %{
            mentioned_user: mention(user, anonymization: false, mosaic: true),
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

  @spec start_timed_task(Verification.t(), Scheme.t(), integer(), integer()) :: :ok
  @doc """
  启动定时任务处理验证超时。
  # TODO: 根据 scheme 决定执行的动作
  """
  def start_timed_task(verification, scheme, seconds, reminder_message_id)
      when is_integer(seconds) and is_integer(reminder_message_id) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} =
      verification

    target_user = %{id: target_user_id, fullname: target_user_name}

    unban_fun = fn ->
      async(fn -> Telegex.unban_chat_member(chat_id, target_user_id) end,
        seconds: allow_join_again_seconds()
      )
    end

    ban_fun = fn latest_verification ->
      if latest_verification.status == :waiting do
        # 更新状态为超时
        latest_verification |> VerificationBusiness.update(%{status: :timeout})
        # TODO: 此处需要根据 scheme
        # 实施操作（踢出）
        kick(chat_id, target_user, :timeout)
        # 解除限制以允许再次加入
        unban_fun.()
      end
    end

    timed_task = fn ->
      # 读取验证记录，为等待状态则实施操作
      case VerificationBusiness.get(verification.id) do
        {:ok, latest_verification} ->
          ban_fun.(latest_verification)

        e ->
          Logger.unitized_error("After the scheduled task is executed, the verification finding",
            verification_id: verification.id,
            returns: e
          )
      end

      # TODO: 此处需要根据 scheme
      # 如果还存在多条验证，更新入口消息

      waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

      if waiting_count == 0 do
        # 已经没有剩余验证，直接删除上一个入口消息
        Cleaner.delete_latest_verification_message(chat_id)
      else
        # 如果还存在多条验证，更新入口消息
        max_seconds = scheme.seconds || countdown()

        VerificationCaller.update_unity_message(
          chat_id,
          waiting_count,
          max_seconds
        )
      end
    end

    async(timed_task, seconds: seconds)
  end

  @type reason :: :wronged | :timeout

  @spec kick(integer(), map(), reason()) :: :ok | {:error, Telegex.Model.errors()}
  def kick(chat_id, user, reason) when is_integer(chat_id) and is_map(user) and is_atom(reason) do
    # 踢出用户
    Telegex.kick_chat_member(chat_id, user.id)
    # 解除限制以允许再次加入
    async(fn -> Telegex.unban_chat_member(chat_id, user.id) end,
      seconds: allow_join_again_seconds()
    )

    time_text =
      if allow_join_again_seconds() < 60,
        do: "#{allow_join_again_seconds()} #{t("units.sec")}",
        else: "#{to_string(trunc(allow_join_again_seconds() / 60))} #{t("units.min")}"

    text =
      case reason do
        :timeout ->
          t("verification.timeout.kick.notice", %{
            mentioned_user: mention(user, anonymization: false, mosaic: true),
            time_text: time_text
          })

        :wronged ->
          t("verification.wronged.kick.notice", %{
            mentioned_user: mention(user, anonymization: false, mosaic: true),
            time_text: time_text
          })
      end

    async(fn -> chat_id |> typing() end)

    case send_message(chat_id, text, parse_mode: "MarkdownV2ToHTML") do
      {:ok, sended_message} ->
        Cleaner.delete_message(chat_id, sended_message.message_id, delay_seconds: 8)

        :ok

      e ->
        Logger.unitized_error("User killed notification",
          chat_id: chat_id,
          user_id: user.id,
          returns: e
        )

        e
    end
  end
end
