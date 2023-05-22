defmodule PolicrMiniBot.VerificationHelper do
  @moduledoc false

  alias PolicrMini.{Counter, Chats}
  alias PolicrMini.Chats.{Verification, Scheme}
  alias PolicrMiniBot.{Worker, EntryMaintainer}
  alias Telegex.Model.User, as: TgUser
  alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

  import PolicrMiniBot.Helper
  import PolicrMiniBot.MessageCaller

  use PolicrMini.I18n

  require Logger

  @type tgerr :: Telegex.Model.errors()
  @type tgmsg :: Telegex.Model.Message.t()
  @type source :: :joined | :join_request

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
      # TODO: 当方案为空时，返回一个默认的方案
      scheme = Chats.find_scheme(chat_id)
      # 异步限制成员权限
      async_run(fn -> restrict_chat_member(chat_id, user.id) end)

      # 生成验证数据
      params = %{
        target_user_name: fullname(user),
        target_user_language_code: user.language_code,
        seconds: scheme.seconds || default!(:vseconds),
        source: :joined
      }

      # 主要流程：创建（或获取进行中的）验证数据，验证入口消息，并更新验证数据中的消息 ID
      with {:ok, v} <- Chats.get_or_create_pending_verification(chat_id, user.id, params),
           {:ok, %{message_id: message_id}} <- put_entry_message(v, scheme),
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

  @spec expired?(integer) :: boolean
  def expired?(date) do
    DateTime.diff(DateTime.utc_now(), DateTime.from_unix!(date)) >= @expire_secs
  end

  @spec put_entry_message(Verification.t(), Scheme.t(), keyword) :: {:ok, tgmsg} | {:error, tgerr}
  def put_entry_message(v, scheme, opts \\ []) do
    %{chat_id: chat_id, target_user_id: target_user_id, target_user_name: target_user_name} = v

    new_chat_user = %{id: target_user_id, fullname: target_user_name}

    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    pending_count =
      Keyword.get(opts, :pending_count) || Chats.get_pending_verification_count(chat_id)

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
      if Keyword.get(opts, :edit, false) do
        make_text_editor(text, Keyword.get(opts, :message_id))
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
    EntryMaintainer.put_entry_message(caller, chat_id, call_opts)
  end
end
