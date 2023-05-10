defmodule PolicrMiniBot.RespStartCmdPlug do
  @moduledoc """
  `/start` 命令。

  与其它命令不同，`/start` 命令不需要保证完整的匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。
  这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。
  """

  use PolicrMiniBot, plug: [commander: :start]

  alias PolicrMini.{Chats, VerificationBusiness, MessageSnapshotBusiness}
  alias PolicrMini.Schema.Verification
  alias PolicrMiniBot.{ArithmeticCaptcha, CustomCaptcha, FallbackCaptcha, ImageCaptcha}
  alias Telegex.Model.{Message, InlineKeyboardMarkup, InlineKeyboardButton}

  require Logger

  @type captcha_data :: PolicrMiniBot.Captcha.Data.t()
  @type tgerr :: Telegex.Model.errors()
  @type tgmsg :: Telegex.Model.Message.t()

  @fallback_captcha_module FallbackCaptcha

  @captchas_mapping [
    image: ImageCaptcha,
    custom: CustomCaptcha,
    arithmetic: ArithmeticCaptcha,
    # 当前的备用验证就是主动验证
    initiative: FallbackCaptcha
  ]

  @doc """
  重写匹配规则，以 `/start` 开始即匹配。
  """
  @impl true
  def match(text, state) do
    if String.starts_with?(text, @command) do
      {:match, state}
    else
      {:nomatch, state}
    end
  end

  @doc """
  - 群组消息，忽略。
  - 群组（超级群）消息，忽略。
  - 如果命令没有携带参数，则发送包含链接的项目介绍。否则将参数整体传递给 `dispatch/1` 函数进一步拆分和分发。
  """
  @impl true
  def handle(%{chat: %{type: "group"}}, state), do: {:ignored, state}

  @impl true
  def handle(%{chat: %{type: "supergroup"}}, state), do: {:ignored, state}

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, text: text} = message

    args = String.split(text, " ")

    if length(args) == 2 do
      args |> List.last() |> dispatch(message)
    else
      ttext =
        commands_text("""
        你好，我是一个专注于新成员验证的机器人。具有稳定的服务，便于操作的网页后台，不断增强与优化的核心功能，并保持长期维护。同时我是开源的，可自由复制部署的。

        访问<a href="https://github.com/Hentioe/policr-mini">这里</a>更加了解一下我吧~
        """)

      send_message(chat_id, ttext, reply_markup: default_markup(), parse_mode: "HTML")
    end

    {:ok, state}
  end

  defp default_markup do
    %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "添加到群聊",
            url: "https://t.me/#{PolicrMiniBot.username()}?startgroup=added"
          }
        ]
      ]
    }
  end

  @doc """
  分发命令参数。
  以 `_` 分割成更多参数，转发给 `handle_args/1` 函数处理。
  """
  def dispatch(arg, message), do: arg |> String.split("_") |> handle_args(message)

  @spec handle_args([binary, ...], Message.t()) :: :ok | {:error, Telegex.Model.errors()}

  # 处理 v1 版本的验证参数。
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = message) do
    target_chat_id = target_chat_id |> String.to_integer()

    if verification = VerificationBusiness.find_waiting_verification(target_chat_id, from_user_id) do
      # 读取验证方案（当前的实现没有实际根据方案数据动态决定什么）
      with {:ok, scheme} <- Chats.fetch_scheme(target_chat_id),
           # 发送验证消息
           {:ok, {verification_message, markup, captcha_data}} <-
             send_verify_message(verification, scheme, target_chat_id, from_user_id),
           # 创建消息快照
           {:ok, message_snapshot} <-
             MessageSnapshotBusiness.create(%{
               chat_id: target_chat_id,
               message_id: verification_message.message_id,
               from_user_id: from_user_id,
               from_user_name: fullname(message.from),
               date: verification_message.date,
               text: verification_message.text,
               markup_body: Jason.encode!(markup, pretty: false),
               caption: verification_message.caption,
               photo_id: get_photo_id(verification_message),
               attachment: captcha_data.attachment
             }),
           # 更新验证记录：关联消息快照、存储正确答案
           {:ok, _} <-
             VerificationBusiness.update(verification, %{
               message_snapshot_id: message_snapshot.id,
               indices: captcha_data.correct_indices
             }) do
        :ok
      else
        {:error, %{error_code: 403}} = e ->
          Logger.warning(
            "Verification creation failed due to user blocking: #{inspect(user_id: from_user_id)}",
            chat_id: target_chat_id
          )

          e

        {:error, reason} = e ->
          Logger.error(
            "Create verification failed: #{inspect(user_id: from_user_id, reason: reason)}",
            chat_id: target_chat_id
          )

          send_message(from_user_id, t("errors.unknown"))

          e
      end
    else
      send_message(from_user_id, t("errors.verification_no_wating"))
    end
  end

  # 响应未知参数。
  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_message(chat_id, t("errors.dont_understand"))
  end

  @type tgerror_returns :: {:error, Telegex.Model.errors()}

  @doc """
  发送验证消息。
  """
  @spec send_verify_message(Verification.t(), PolicrMini.Chats.Scheme.t(), integer, integer) ::
          tgerror_returns
          | {:ok, {Message.t(), InlineKeyboardMarkup.t(), PolicrMiniBot.Captcha.Data.t()}}
  def send_verify_message(verification, scheme, chat_id, user_id) do
    mode = scheme.verification_mode || default!(:vmode)

    captcha_module = @captchas_mapping[mode] || @fallback_captcha_module

    data =
      try do
        captcha_module.make!(chat_id, scheme)
      rescue
        e ->
          Logger.warning(
            "Verification data generation failed: #{inspect(exception: e)}",
            chat_id: chat_id
          )

          @fallback_captcha_module.make!(chat_id, scheme)
      end

    markup = PolicrMiniBot.Captcha.build_markup(data.candidates, verification.id)

    ttitle =
      commands_text("来自『%{chat_title}』的验证，请确认问题并选择您认为正确的答案。",
        chat_title: "*#{escape_markdown(verification.chat.title)}*"
      )

    tfooter = commands_text("您还剩 %{sec} 秒，通过可解除限制。", sec: "__#{time_left_text(verification)}__")

    text = """
    #{ttitle}

    *#{escape_markdown(data.question)}*

    #{tfooter}
    """

    # 发送验证消息
    case send_verification(user_id, text, data, markup, "MarkdownV2") do
      {:ok, sended_message} ->
        {:ok, {sended_message, markup, data}}

      e ->
        e
    end
  end

  @spec send_verification(integer, String.t(), captcha_data, InlineKeyboardMarkup.t(), binary) ::
          {:ok, tgmsg} | {:error, tgerr}

  # 发送图片验证消息
  def send_verification(chat_id, text, %{photo: photo} = _data, markup, parse_mode)
      when photo != nil do
    send_attachment(chat_id, "photo/#{photo}",
      caption: text,
      reply_markup: markup,
      parse_mode: parse_mode,
      logging: true
    )
  end

  # 发送附件验证消息
  def send_verification(chat_id, text, %{attachment: attachment} = _data, markup, parse_mode)
      when attachment != nil do
    send_attachment(chat_id, attachment,
      caption: text,
      reply_markup: markup,
      parse_mode: parse_mode,
      logging: true
    )
  end

  # 发送文本验证消息
  def send_verification(chat_id, text, _data, markup, parse_mode) do
    send_text(chat_id, text,
      reply_markup: markup,
      parse_mode: parse_mode
    )
  end

  @type captchas :: ImageCaptcha | CustomCaptcha | ArithmeticCaptcha | FallbackCaptcha
  @type send_returns :: {:ok, Message.t()} | {:error, Telegex.Model.errors()}

  @doc """
  根据验证记录计算剩余时间
  """
  @spec time_left_text(Verification.t()) :: integer()
  def time_left_text(%Verification{seconds: seconds, inserted_at: inserted_at}) do
    seconds - DateTime.diff(DateTime.utc_now(), inserted_at)
  end

  def get_photo_id(%Telegex.Model.Message{photo: [%Telegex.Model.PhotoSize{file_id: file_id} | _]}),
      do: file_id

  def get_photo_id(%Telegex.Model.Message{photo: []}), do: nil
  def get_photo_id(%Telegex.Model.Message{photo: nil}), do: nil
end
