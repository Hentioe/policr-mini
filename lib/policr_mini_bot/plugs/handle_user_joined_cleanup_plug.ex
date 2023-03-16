defmodule PolicrMiniBot.HandleUserJoinedCleanupPlug do
  @moduledoc """
  处理新用户加入。
  """

  # TODO: 修改模块含义并迁移代码。因为设计改动，此 `:message_handler` 已无实际验证处理流程，仅作删除消息之用。

  use PolicrMiniBot, plug: :message_handler

  alias PolicrMini.{Logger, Chats}
  alias PolicrMini.Chats.Scheme
  alias PolicrMini.Schema.Verification
  alias PolicrMini.VerificationBusiness
  alias PolicrMiniBot.Worker

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

    # TOD0: 将 scheme 的获取放在一个独立的 plug 中，通过状态传递。
    case Chats.fetch_scheme(chat_id) do
      {:ok, scheme} ->
        service_message_cleanup = scheme.service_message_cleanup || default!(:smc) || []

        if Enum.member?(service_message_cleanup, :joined) do
          # 删除服务消息。
          Worker.async_delete_message(chat_id, message.message_id)
        end
    end

    {:ok, %{state | done: true, deleted: true}}
  end

  # 处理单个新成员的加入。
  def handle_one(chat_id, new_chat_member, date, scheme, state) do
    joined_datetime =
      case date |> DateTime.from_unix() do
        {:ok, datetime} -> datetime
        _ -> DateTime.utc_now()
      end

    mode = scheme.verification_mode || default!(:vmode)
    seconds = scheme.seconds || default!(:vseconds)

    if DateTime.diff(DateTime.utc_now(), joined_datetime) >= @expired_seconds do
      # 处理过期验证
      handle_expired(chat_id, new_chat_member, state)
    else
      # 异步限制新用户
      async_run(fn -> restrict_chat_member(chat_id, new_chat_member.id) end)

      handle_it(mode, seconds, chat_id, new_chat_member, state)
    end
  end

  @doc """
  处理过期验证。
  当前仅限制用户，并不发送验证消息。
  """
  @spec handle_expired(integer, map, State.t()) :: {:error, State.t()} | {:ok, State.t()}
  def handle_expired(chat_id, new_chat_member, state) do
    verification_params = %{
      chat_id: chat_id,
      target_user_id: new_chat_member.id,
      target_user_name: fullname(new_chat_member),
      target_user_language_code: new_chat_member.language_code,
      seconds: 0,
      status: :expired
    }

    case VerificationBusiness.fetch(verification_params) do
      {:ok, _} ->
        # 计数器自增（验证总数）
        PolicrMini.Counter.increment(:verification_total)
        # 异步限制新用户
        async_run(fn -> restrict_chat_member(chat_id, new_chat_member.id) end)

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
  def handle_it(_, seconds, chat_id, new_chat_member, state) do
    verification_params = %{
      chat_id: chat_id,
      target_user_id: new_chat_member.id,
      target_user_name: fullname(new_chat_member),
      target_user_language_code: new_chat_member.language_code,
      seconds: seconds,
      status: :waiting
    }

    with {:ok, verification} <- VerificationBusiness.fetch(verification_params),
         {:ok, scheme} <- Chats.fetch_scheme(chat_id),
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

      # 异步延迟处理超时
      Worker.async_terminate_validation(verification, scheme, seconds)

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
end
