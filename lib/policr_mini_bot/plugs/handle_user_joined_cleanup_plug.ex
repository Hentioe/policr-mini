defmodule PolicrMiniBot.HandleUserJoinedCleanupPlug do
  @moduledoc """
  处理新用户加入。
  """

  # TODO: 修改模块含义并迁移代码。因为设计改动，此 `:message_handler` 已无实际验证处理流程，仅作删除消息之用。

  use PolicrMiniBot, plug: :message_handler

  alias PolicrMini.Logger

  alias PolicrMini.Chats.Scheme
  alias PolicrMini.Schema.Verification
  alias PolicrMini.{SchemeBusiness, VerificationBusiness, StatisticBusiness, OperationBusiness}
  alias PolicrMiniBot.CallVerificationPlug

  # 过期时间：15 分钟
  @expired_seconds 60 * 15

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

    # 异步删除服务消息
    Cleaner.delete_message(chat_id, message.message_id)

    {:ok, %{state | done: true, deleted: true}}
  end

  # 处理单个新成员的加入。
  def handle_one(chat_id, new_chat_member, date, scheme, state) do
    joined_datetime =
      case date |> DateTime.from_unix() do
        {:ok, datetime} -> datetime
        _ -> DateTime.utc_now()
      end

    entrance = scheme.verification_entrance || default!(:ventrance)
    mode = scheme.verification_mode || default!(:vmode)
    occasion = scheme.verification_occasion || default!(:voccasion)
    seconds = scheme.seconds || default!(:vseconds)

    if DateTime.diff(DateTime.utc_now(), joined_datetime) >= @expired_seconds do
      # 处理过期验证
      handle_expired(entrance, chat_id, new_chat_member, state)
    else
      # 异步限制新用户
      async(fn -> restrict_chat_member(chat_id, new_chat_member.id) end)

      handle_it(mode, entrance, occasion, seconds, chat_id, new_chat_member, state)
    end
  end

  @doc """
  处理过期验证。
  当前仅限制用户，并不发送验证消息。
  """
  @spec handle_expired(atom, integer, map, State.t()) :: {:error, State.t()} | {:ok, State.t()}
  def handle_expired(entrance, chat_id, new_chat_member, state) do
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
        # 计数器自增（验证总数）
        PolicrMini.Counter.increment(:verification_total)
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
  def handle_it(_, :unity, :private, seconds, chat_id, new_chat_member, state) do
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
         {:ok, scheme} <- SchemeBusiness.fetch(chat_id),
         {text, markup} <- make_verify_content(verification, scheme, seconds),
         {:ok, reminder_message} <-
           Cleaner.send_verification_message(chat_id, text,
             reply_markup: markup,
             parse_mode: "MarkdownV2ToHTML"
           ),
         {:ok, _} <-
           VerificationBusiness.update(verification, %{message_id: reminder_message.message_id}) do
      # 计数器自增（验证总数）
      PolicrMini.Counter.increment(:verification_total)

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
  @spec make_verify_content(Verification.t(), Scheme.t(), integer) ::
          {String.t(), InlineKeyboardMarkup.t()}
  def make_verify_content(verification, scheme, seconds)
      when is_struct(verification, Verification) and is_struct(scheme, Scheme) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} =
      verification

    new_chat_member = %{id: target_user_id, fullname: target_user_name}

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

    make_unity_content(chat_id, new_chat_member, waiting_count, scheme, seconds)
  end

  @doc """
  生成统一验证入口消息。

  参数 `user` 需要满足 `PolicrMiniBot.Helper.fullname/1` 函数子句的匹配。
  """
  @spec make_unity_content(
          integer,
          PolicrMiniBot.Helper.mention_user(),
          integer,
          Scheme.t(),
          integer
        ) ::
          {String.t(), InlineKeyboardMarkup.t()}

  def make_unity_content(chat_id, user, waiting_count, scheme, seconds)
      when is_struct(scheme, Scheme) do
    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    mention_scheme = scheme.mention_text || default!(:mention_scheme)

    text =
      if waiting_count == 1,
        do:
          t("verification.unity.single_waiting", %{
            mentioned_user: build_mention(user, mention_scheme),
            seconds: seconds
          }),
        else:
          t("verification.unity.multiple_waiting", %{
            mentioned_user: build_mention(user, mention_scheme),
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

  @spec start_timed_task(Verification.t(), Scheme.t(), integer, integer) :: :ok
  @doc """
  启动定时任务处理验证超时。
  """
  def start_timed_task(verification, scheme, seconds, reminder_msg_id)
      when is_integer(seconds) and is_integer(reminder_msg_id) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} =
      verification

    target_user = %{id: target_user_id, fullname: target_user_name}

    handle_verification_fun = fn latest_verification ->
      # 为等待状态则实施操作
      if latest_verification.status == :waiting do
        # 自增统计数据（超时）。
        async do
          StatisticBusiness.increment_one(
            verification.chat_id,
            verification.target_user_language_code,
            :timeout
          )
        end

        timeout_killing_method = scheme.timeout_killing_method || default!(:tkmethod)

        # 添加操作记录（系统）
        create_operation(latest_verification, timeout_killing_method)

        # 计数器自增（超时总数）
        PolicrMini.Counter.increment(:verification_timeout_total)
        # 更新状态为超时
        latest_verification |> VerificationBusiness.update(%{status: :timeout})
        # 击杀用户（原因为超时）。
        CallVerificationPlug.kill(chat_id, target_user, :timeout, timeout_killing_method)
      end
    end

    timed_task = fn ->
      # 读取验证记录，并根据状态实时操作
      case VerificationBusiness.get(verification.id) do
        {:ok, latest_verification} ->
          handle_verification_fun.(latest_verification)

        e ->
          Logger.unitized_error("After the scheduled task is executed, the verification finding",
            verification_id: verification.id,
            returns: e
          )
      end

      # 如果还存在多条验证，更新入口消息
      waiting_count = VerificationBusiness.get_unity_waiting_count(chat_id)

      if waiting_count == 0 do
        # 已经没有剩余验证，直接删除上一个入口消息
        Cleaner.delete_latest_verification_message(chat_id)
      else
        # 如果还存在多条验证，更新入口消息
        CallVerificationPlug.update_unity_message(
          chat_id,
          waiting_count,
          scheme,
          seconds
        )
      end
    end

    async(timed_task, seconds: seconds)
  end

  defp create_operation(verification, killing_method) do
    operation_action = if killing_method == :ban, do: :ban, else: :kick
    # 添加操作记录（系统）。
    case OperationBusiness.create(%{
           verification_id: verification.id,
           action: operation_action,
           role: :system
         }) do
      {:ok, _} = r ->
        r

      e ->
        Logger.unitized_error("Operation creation", e)

        e
    end
  end
end
