defmodule PolicrMiniBot.VerificationHelper do
  @moduledoc false

  # TODO: 疑似存在验证入口消息的更新顺序问题。假设 B 用户覆盖了 A 用户的入口，B 结束时应该重新显示 A。错误在于继续显示了 B 用户的入口消息文本。

  alias PolicrMini.{Repo, Counter, Chats}
  alias PolicrMini.Chats.{Verification, Scheme}
  alias PolicrMiniBot.{Worker, EntryMaintainer, Captcha, JoinReuquestHosting}
  alias Telegex.Model.User, as: TgUser
  alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

  use PolicrMini.I18n
  use PolicrMiniBot.MessageCaller

  import PolicrMiniBot.Helper

  require Logger

  @type tgerr :: Telegex.Model.errors()
  @type tgmsg :: Telegex.Model.Message.t()
  @type captcha_data :: Captcha.Data.t()
  @type send_opts :: MessageCaller.call_opts()
  @type source :: :joined | :join_request
  @type kreason :: :wronged | :timeout | :kick | :ban | :manual_ban | :manual_kick
  @type kmethod :: :ban | :kick

  # 过期时间：15 分钟
  @expire_secs 60 * 15

  @doc """
  向用户发送验证消息或在群聊中发送验证入口消息（取决于用户来源）。无论来源如何，都会生成并返回验证记录。函数名 `embarrass_user` 表达了为难加群用户（或群成员）的含义，因为机器人将要出题考他们。

  理论上此函数可以验证已存在的群成员，但存在一些未知数，并且未经测试。
  """
  @spec embarrass_user(source, integer, TgUser.t(), integer) ::
          {:ok, Verification.t()} | {:error, any}
  def embarrass_user(:joined, chat_id, user, date) do
    embarrass_joined_user(chat_id, user, date: date)
  end

  def embarrass_user(:join_request, chat_id, user, date) do
    embarrass_request_user(chat_id, user, date)
  end

  @spec embarrass_joined_user(integer, TgUser.t(), keyword) ::
          {:ok, Verification.t()} | {:error, any}
  def embarrass_joined_user(chat_id, user, opts \\ []) do
    date = Keyword.get(opts, :date, 0)

    if date > 0 && expired?(date) do
      # 创建过期的验证
      params = %{
        chat_id: chat_id,
        target_user_id: user.id,
        target_user_name: fullname(user),
        target_user_language_code: user.language_code,
        seconds: 0,
        status: :expired,
        source: :joined
      }

      case Chats.create_verification(params) do
        {:ok, _v} = ok_r ->
          # 计数器自增（验证总数）
          PolicrMini.Counter.increment(:verification_total)
          # 异步限制新用户
          async_run(fn -> restrict_chat_member(chat_id, user.id) end)

          ok_r

        {:error, reason} = e ->
          Logger.error(
            "Create verification failed: #{inspect(user_id: user.id, reason: reason)}",
            chat_id: chat_id
          )

          e
      end
    else
      # 载入方案
      scheme = Chats.find_or_init_scheme!(chat_id)
      # 异步限制成员权限
      async_run(fn -> restrict_chat_member(chat_id, user.id) end)

      # 生成验证数据
      params = %{
        target_user_name: fullname(user),
        target_user_language_code: user.language_code,
        seconds: scheme.seconds || default!(:vseconds),
        source: :joined
      }

      # 主要流程：
      # 1. 创建（或获取进行中的）验证数据
      # 2. 尝试转换可能不匹配的数据来源
      # 3. 写入到入口消息
      # 4. 更新验证数据中的消息 ID
      with {:ok, v} <- Chats.get_or_create_pending_verification(chat_id, user.id, params),
           {:ok, v} <- try_convert_souce(:joined, v, scheme),
           {:ok, %{message_id: message_id}} <- put_entry_message(v, scheme, []),
           {:ok, v} = ok_r <- Chats.update_verification(v, %{message_id: message_id}) do
        # 验证创建成功

        # 计数器自增（验证总数）
        Counter.increment(:verification_total)

        # 创建异步任务处理超时
        Worker.async_terminate_validation(v, scheme, v.seconds)

        ok_r
      else
        {:error, reason} = e ->
          Logger.error(
            "Embarrass joined user failed: #{inspect(reason: reason)}",
            chat_id: chat_id
          )

          tdesc =
            commands_text("发生了一些错误，针对 %{mention} 的验证创建失败。建议管理员自行鉴别再决定取消限制或手动封禁。",
              mention: mention(user)
            )

          tcomment = commands_text("如果反复出现此问题，请取消接管状态并通知开发者。")

          text = """
          #{tdesc}

          #{tcomment}
          """

          send_message(chat_id, text)

          e
      end
    end
  end

  @spec embarrass_request_user(integer, TgUser.t(), integer) ::
          {:ok, Verification.t()} | {:error, any}
  def embarrass_request_user(chat_id, user, date) do
    if date > 0 && expired?(date) do
      # 拒绝加群请求
      Telegex.decline_chat_join_request(chat_id, user.id)

      # 创建过期的验证
      params = %{
        chat_id: chat_id,
        target_user_id: user.id,
        target_user_name: fullname(user),
        target_user_language_code: user.language_code,
        seconds: 0,
        status: :expired,
        source: :join_request
      }

      case Chats.create_verification(params) do
        {:ok, _v} = ok_r ->
          # 计数器自增（验证总数）
          PolicrMini.Counter.increment(:verification_total)
          # 异步拒绝加群请求
          async_run(fn -> Telegex.decline_chat_join_request(chat_id, user.id) end)

          ok_r

        {:error, reason} = e ->
          Logger.error(
            "Create verification failed: #{inspect(user_id: user.id, reason: reason)}",
            chat_id: chat_id
          )

          e
      end
    else
      # 载入方案
      scheme = Chats.find_or_init_scheme!(chat_id)

      # 生成验证数据
      params = %{
        target_user_name: fullname(user),
        target_user_language_code: user.language_code,
        seconds: scheme.seconds || default!(:vseconds),
        source: :join_request
      }

      # 主要流程：
      # 1. 创建（或获取进行中的）验证数据
      # 2. 尝试转换可能不匹配的数据来源
      # 3. 写入到入口消息
      # 4. 更新验证数据中的消息 ID
      # 5. 发送验证
      with {:ok, v} <- Chats.get_or_create_pending_verification(chat_id, user.id, params),
           {:ok, v} <- try_convert_souce(:join_request, v, scheme),
           {:ok, %{message_id: message_id}} <- put_entry_message(v, scheme, []),
           {:ok, v} <- Chats.update_verification(v, %{message_id: message_id}),
           {:ok, v} = ok_r <- send_verification(Repo.preload(v, [:chat]), scheme) do
        # 验证创建成功

        # 托管加入请求
        :ok = JoinReuquestHosting.put(chat_id, user.id, date, :pending)

        # 计数器自增（验证总数）
        Counter.increment(:verification_total)

        # 创建异步任务处理超时
        Worker.async_terminate_validation(v, scheme, v.seconds)

        ok_r
      else
        # TODO: 单独处理用户拉黑等不能主动与之沟通的错误。

        {:error, reason} = e ->
          Logger.error(
            "Embarrass request user failed: #{inspect(reason: reason)}",
            chat_id: chat_id
          )

          tdesc =
            commands_text("发生了一些错误，针对 %{mention} 的验证创建失败。建议管理员自行鉴别并决定通过或拒绝加群请求。",
              mention: mention(user)
            )

          tcomment = commands_text("如果反复出现此问题，请取消接管状态并通知开发者。")

          text = """
          #{tdesc}

          #{tcomment}
          """

          send_message(chat_id, text)

          e
      end
    end
  end

  @spec expired?(integer) :: boolean
  def expired?(date) do
    DateTime.diff(DateTime.utc_now(), DateTime.from_unix!(date)) >= @expire_secs
  end

  @doc """
  比对目标来源和验证数据，当不对应时进行转换。
  """
  @spec try_convert_souce(source, Verification.t(), Scheme.t()) ::
          {:ok, Verification.t()} | {:error, any}
  # 将 `:joined` 转换为 `:join_request` 验证
  def try_convert_souce(:join_request, %{source: :joined} = v, scheme) do
    # 更新来源数据并更新入口消息
    with {:ok, _} = ok_r <- Chats.update_verification(v, %{source: :join_request}),
         # 由于更新的是旧入口消息，所以此处不使用更新来源后的验证数据
         :ok <- put_or_delete_entry_message(v, scheme) do
      # 解除之前的权限限制
      async_run(fn -> derestrict_chat_member(v.chat_id, v.target_user_id) end)

      ok_r
    else
      e -> e
    end
  end

  # 将 `:join_request` 转换为 `:joined` 验证
  def try_convert_souce(:joined, %{source: :join_request} = v, scheme) do
    # 更新来源数据并更新入口消息
    with {:ok, _} = ok_r <- Chats.update_verification(v, %{source: :joined}),
         # 由于更新的是旧入口消息，所以此处不使用更新来源后的验证数据
         :ok <- put_or_delete_entry_message(v, scheme) do
      # 拒绝之前的加群请求
      async_run(fn -> Telegex.decline_chat_join_request(v.chat_id, v.target_user_id) end)

      ok_r
    else
      e -> e
    end
  end

  # 目标来源和验证数据相匹配，直接返回验证数据
  def try_convert_souce(_, v, _scheme), do: {:ok, v}

  @spec put_or_delete_entry_message(Verification.t(), Scheme.t()) :: :ok | {:error, any}
  def put_or_delete_entry_message(v, scheme) do
    count = Chats.get_pending_verification_count(v.chat_id, v.source)

    if count == 0 do
      # 如果没有等待验证了，立即删除入口消息
      EntryMaintainer.delete_entry_message(v.source, v.chat_id)
    else
      # 获取最新的验证入口消息编号
      message_id = Chats.find_last_verification_message_id(v.chat_id, v.source)

      # 更新入口消息
      put_entry_message(v, scheme, pending_count: count, message_id: message_id)
    end

    :ok
  end

  @type put_entry_message_opts :: [pending_count: integer, message_id: integer]

  @spec put_entry_message(Verification.t(), Scheme.t(), put_entry_message_opts) ::
          {:ok, tgmsg} | {:error, tgerr}
  def put_entry_message(%{source: :joined} = v, scheme, opts) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} = v

    new_chat_user = %{id: target_user_id, fullname: target_user_name}

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    pending_count =
      Keyword.get(opts, :pending_count) || Chats.get_pending_verification_count(chat_id, :joined)

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    mention_scheme = scheme.mention_text || default!(:mention_scheme)

    text =
      if pending_count == 1 do
        thello =
          commands_text("新成员 %{mention} 你好！",
            mention: build_mention(new_chat_user, mention_scheme)
          )

        tdesc = commands_text("您当前需要完成验证才能解除限制，验证有效时间不超过 __%{seconds}__ 秒。", seconds: v.seconds)
        tfooter = commands_text("过期会被踢出或封禁，请尽快。")

        """
        #{thello}

        #{tdesc}
        #{tfooter}
        """
      else
        thello =
          commands_text("刚来的 %{mention} 和另外 %{remaining_count} 个还未验证的新成员，你们好！",
            mention: build_mention(new_chat_user, mention_scheme),
            remaining_count: pending_count - 1
          )

        tdesc = commands_text("请主动完成验证以解除限制，验证有效时间不超过 __%{seconds}__ 秒。", seconds: v.seconds)
        tfooter = commands_text("过期会被踢出或封禁，请尽快。")

        """
        #{thello}

        #{tdesc}
        #{tfooter}
        """
      end

    caller =
      if message_id = Keyword.get(opts, :message_id) do
        make_text_editor(text, message_id)
      else
        make_text_sender(text)
      end

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: commands_text("点此验证"),
            url: "https://t.me/#{bot_username()}?start=verification_v1_#{chat_id}"
          }
        ]
      ]
    }

    call_opts = [
      reply_markup: markup,
      disable_notification: true,
      disable_web_page_preview: false,
      parse_mode: "MarkdownV2"
    ]

    # 更新到群聊的入口消息中
    EntryMaintainer.put_entry_message(v.source, caller, chat_id, call_opts)
  end

  def put_entry_message(%{source: :join_request} = v, scheme, opts) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} = v

    new_chat_user = %{id: target_user_id, fullname: target_user_name}

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    pending_count =
      Keyword.get(opts, :pending_count) ||
        Chats.get_pending_verification_count(chat_id, :join_request)

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    mention_scheme = scheme.mention_text || default!(:mention_scheme)

    text =
      if pending_count == 1 do
        theader =
          commands_text("用户 %{mention} 正在验证！",
            mention: build_mention(new_chat_user, mention_scheme)
          )

        tdesc = commands_text("加群请求会根据验证结果自动处理，并按照方案决定是否进一步封禁。")
        tfooter = commands_text("验证有效时间不超过 __%{seconds}__ 秒。", seconds: v.seconds)

        """
        #{theader}

        #{tdesc}
        #{tfooter}
        """
      else
        theader =
          commands_text("刚刚申请加入的 %{mention} 和另外 %{remaining_count} 个用户正在验证！",
            mention: build_mention(new_chat_user, mention_scheme),
            remaining_count: pending_count - 1
          )

        tdesc = commands_text("加群请求会根据验证结果自动处理，并按照方案决定是否进一步封禁。")
        tfooter = commands_text("验证有效时间不超过 __%{seconds}__ 秒。", seconds: v.seconds)

        """
        #{theader}

        #{tdesc}
        #{tfooter}
        """
      end

    caller =
      if message_id = Keyword.get(opts, :message_id) do
        make_text_editor(text, message_id)
      else
        make_text_sender(text)
      end

    call_opts = [
      disable_notification: true,
      disable_web_page_preview: false,
      parse_mode: "MarkdownV2"
    ]

    # 更新到群聊的入口消息中
    EntryMaintainer.put_entry_message(v.source, caller, chat_id, call_opts)
  end

  @doc """
  发送并更新验证。

  如果验证发送成功，验证记录将被更新（包含正确答案），并返回更新后的验证记录。
  """
  @spec send_verification(Verification.t(), Scheme.t()) ::
          {:ok, Verification.t()} | {:error, any}
  def send_verification(v, scheme) do
    mode = scheme.verification_mode || default!(:vmode)
    data = Captcha.make(mode, v.chat_id, scheme)

    ttitle =
      commands_text("来自『%{chat_title}』的验证，请确认问题并选择您认为正确的答案。",
        chat_title: "*#{escape_markdown(v.chat.title)}*"
      )

    tfooter = commands_text("您还剩 %{sec} 秒，通过可解除限制。", sec: "__#{time_left_text(v)}__")

    text = """
    #{ttitle}

    *#{escape_markdown(data.question)}*

    #{tfooter}
    """

    markup = Captcha.build_markup(data.candidates, v.id)

    send_opts = [
      reply_markup: markup,
      parse_mode: "MarkdownV2",
      disable_web_page_preview: true,
      logging: true
    ]

    with {:ok, _} <- send_verification_message(v, data, text, send_opts),
         {:ok, v} <- Chats.update_verification(v, %{indices: data.correct_indices}) do
      {:ok, v}
    else
      e -> e
    end
  end

  @doc """
  发送验证消息。
  """
  @spec send_verification_message(Verification.t(), captcha_data, String.t(), send_opts) ::
          {:ok, tgmsg} | {:error, tgerr}
  # 发送图片验证消息
  def send_verification_message(v, %{photo: photo} = _captcha_data, text, opts)
      when photo != nil do
    opts = Keyword.merge(opts, caption: text)

    send_attachment(v.target_user_id, "photo/#{photo}", opts)
  end

  # 发送附件验证消息
  def send_verification_message(v, %{attachment: attachment} = _captcha_data, text, opts)
      when attachment != nil do
    opts = Keyword.merge(opts, caption: text)

    send_attachment(v.target_user_id, attachment, opts)
  end

  # 发送文本验证消息
  def send_verification_message(v, _captcha_data, text, opts) do
    send_text(v.target_user_id, text, opts)
  end

  @doc """
  根据验证记录计算剩余时间。
  """
  @spec time_left_text(Verification.t()) :: integer()
  def time_left_text(%Verification{seconds: seconds, inserted_at: inserted_at}) do
    seconds - DateTime.diff(DateTime.utc_now(), inserted_at)
  end

  @doc """
  击杀用户。

  此函数会根据击杀方法做出指定动作，并结合击杀原因发送通知消息。
  """
  @spec kill(Verification.t(), Scheme.t(), kreason) :: :ok | {:error, map}
  def kill(v, scheme, reason) do
    kmethod = scheme.timeout_killing_method || default!(:tkmethod)
    delay_unban_secs = scheme.delay_unban_secs || default!(:delay_unban_secs)

    # 击杀用户
    kill_user(v, kmethod, delay_unban_secs)

    time_text = "#{delay_unban_secs} #{t("units.sec")}"

    user_map = %{id: v.target_user_id, fullname: v.target_user_name}
    mention = mention(user_map, anonymization: false, mosaic: true)

    text = knotifition_text(v.source, reason, kmethod, mention, time_text)

    case send_message(v.chat_id, text, parse_mode: "MarkdownV2ToHTML") do
      {:ok, sended_message} ->
        Worker.async_delete_message(v.chat_id, sended_message.message_id, delay_secs: 8)

        :ok

      {:error, reason} = e ->
        Logger.warning(
          "Send kill user notification failed: #{inspect(user_id: v.target_user_id, reason: reason)}",
          chat_id: v.chat_id
        )

        e
    end
  end

  @spec kill_user(Verification.t(), kmethod, integer) :: {:ok, boolean} | {:error, tgerr}
  defp kill_user(%{source: :joined} = v, kmethod, delay_unban_secs) do
    case kmethod do
      :kick ->
        kick_chat_member(v.chat_id, v.target_user_id, delay_unban_secs)

      :ban ->
        Telegex.ban_chat_member(v.chat_id, v.target_user_id)
    end
  end

  defp kill_user(%{source: :join_request} = v, kmethod, _delay_unban_secs) do
    # 删除托管的加群请求数据
    :ok = JoinReuquestHosting.delete(v.chat_id, v.target_user_id)

    case kmethod do
      :kick ->
        Telegex.decline_chat_join_request(v.chat_id, v.target_user_id)

      :ban ->
        # 拒绝加群请求并封禁
        Telegex.decline_chat_join_request(v.chat_id, v.target_user_id)
        Telegex.ban_chat_member(v.chat_id, v.target_user_id)
    end
  end

  # 构造击杀文字（公聊通知）
  @spec knotifition_text(source, kreason, kmethod, String.t(), String.t()) :: String.t()
  defp knotifition_text(:joined, :timeout, method, mention, time_text) do
    case method do
      :ban ->
        commands_text("刚刚 %{mention} 超时未验证，已被封禁。", mention: mention)

      _ ->
        theader = commands_text("刚刚 %{mention} 超时未验证，已经移出本群。", mention: mention)

        tfooter = commands_text("过 %{time_text}后可再次尝试加入。", time_text: time_text)

        """
        #{theader}

        #{tfooter}
        """
    end
  end

  defp knotifition_text(:joined, :wronged, method, mention, time_text) do
    case method do
      :ban ->
        commands_text("刚刚 %{mention} 验证错误，已被封禁。", mention: mention)

      _ ->
        theader = commands_text("刚刚 %{mention} 验证错误，已经移出本群。", mention: mention)

        tfooter = commands_text("过 %{time_text}后可再次尝试加入。", time_text: time_text)

        """
        #{theader}

        #{tfooter}
        """
    end
  end

  defp knotifition_text(:join_request, :timeout, method, mention, time_text) do
    case method do
      :ban ->
        commands_text("刚刚 %{mention} 超时未验证，已拒绝其加入请求并实施封禁。", mention: mention)

      _ ->
        theader = commands_text("刚刚 %{mention} 超时未验证，已拒绝其加入请求。", mention: mention)

        tfooter = commands_text("过 %{time_text}后可再次申请加入。", time_text: time_text)

        """
        #{theader}

        #{tfooter}
        """
    end
  end

  defp knotifition_text(:join_request, :wronged, method, mention, time_text) do
    case method do
      :ban ->
        commands_text("刚刚 %{mention} 验证错误，已拒绝其加入请求并实施封禁。", mention: mention)

      _ ->
        theader = commands_text("刚刚 %{mention} 验证错误，已拒绝其加入请求。", mention: mention)

        tfooter = commands_text("过 %{time_text}后可再次申请加入。", time_text: time_text)

        """
        #{theader}

        #{tfooter}
        """
    end
  end

  defp knotifition_text(_, :manual_ban, _method, mention, _time_text) do
    commands_text("刚刚 %{mention} 被手动封禁，针对 TA 个人的验证已取消。", mention: mention)
  end

  defp knotifition_text(_, :manual_kick, _method, mention, _time_text) do
    commands_text("刚刚 %{mention} 被手动踢出，针对 TA 个人的验证已取消。", mention: mention)
  end

  @spec kick_chat_member(integer, integer, integer) ::
          {:ok, boolean} | Telegex.Model.errors()
  defp kick_chat_member(chat_id, user_id, delay_unban_secs) do
    case PolicrMiniBot.config(:unban_method) do
      :api_call ->
        r = Telegex.ban_chat_member(chat_id, user_id)

        # 调用 API 解除限制以允许再次加入。
        async_run(fn -> Telegex.unban_chat_member(chat_id, user_id) end,
          delay_secs: delay_unban_secs
        )

        r

      :until_date ->
        Telegex.ban_chat_member(chat_id, user_id, until_date: until_date(delay_unban_secs))
    end
  end

  @spec until_date(integer) :: integer
  defp until_date(delay_unban_secs) do
    dt_now = DateTime.utc_now()
    unix_now = DateTime.to_unix(dt_now)

    # 当前时间加允许重现加入的秒数，确保能正常解除封禁。
    # +1 是为了抵消网络延迟
    unix_now + delay_unban_secs + 1
  end
end
