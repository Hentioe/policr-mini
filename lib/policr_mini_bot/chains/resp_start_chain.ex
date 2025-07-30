defmodule PolicrMiniBot.RespStartChain do
  @moduledoc """
  `/start` 命令。

  与其它命令不同，`/start` 命令不需要保证完整的匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。


  ## 仅匹配一下条件
    - 私聊且以 `/start` 开头的文本消息。
  """

  use PolicrMiniBot.Chain, {:command, :start}

  alias PolicrMini.Chats
  alias Telegex.Type.{InlineKeyboardMarkup, InlineKeyboardButton}

  import PolicrMiniBot.VerificationHelper

  require Logger

  @type captcha_data :: PolicrMiniBot.Captcha.Data.t()
  @type tgerr :: Telegex.Type.error()
  @type tgmsg :: Telegex.Type.Message.t()

  # 重写匹配规则，消息文本以 `/start` 开始的私聊消息即匹配
  @impl true
  def match?(%{text: text, chat: %{type: "private"}}, _context) when text != nil do
    String.starts_with?(text, @command)
  end

  # 其余皆忽略
  @impl true
  def match?(_message, _context), do: false

  # 转发携带参数
  @impl true
  def handle(%{text: <<@command <> " " <> args_text::binary>>} = message, context) do
    args_text
    |> String.trim()
    |> String.split("_")
    |> handle_args(message)

    {:stop, context}
  end

  # 处理空参数
  @impl true
  def handle(%{chat: chat} = _message, context) do
    text = """
    👋 你好，旅行者。我是一个以验证功能为主的机器人。主要功能包括：

    ‧ 提供自定义验证（定制验证）和其它各种验证类型
    ‧ 支持公开群、私有群、管理员全匿名群
    ‧ 兼容已启用/未启用 Approve new members（审核新成员）等多种模式
    ‧ 为机器人拥有者（运营者）设计的全功能 web 后台
    ‧ 为管理员（用户）设计的 Mini Apps 控制台

    我具有稳定的服务，不断增强与优化的核心功能，并保持长期维护。同时我是开源的，可自由复制部署的。

    访问<a href="https://github.com/Hentioe/policr-mini">这里</a>深入了解一下我吧～
    """

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: "添加到群聊",
            url: "https://t.me/#{context.bot.username()}?startgroup=added"
          }
        ]
      ]
    }

    context = %{
      context
      | payload: %{
          method: "sendMessage",
          chat_id: chat.id,
          text: text,
          reply_markup: markup,
          disable_web_page_preview: true,
          parse_mode: "HTML"
        }
    }

    {:done, context}
  end

  # 处理 v1 版本的验证参数
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = _message) do
    target_chat_id = String.to_integer(target_chat_id)

    if v = Chats.find_pending_verification(target_chat_id, from_user_id) do
      scheme = Chats.find_or_init_scheme!(target_chat_id)

      case send_verification(v, scheme) do
        {:ok, _} ->
          :ok

        {:error, :too_many_send_times} ->
          send_text(from_user_id, commands_text("同一个验证的发送次数过多，请使用旧消息完成验证。"), logging: true)

        {:error, %{error_code: 403}} = e ->
          Logger.warning(
            "Verification failed to send due to user blocking: #{inspect(user_id: from_user_id)}",
            chat_id: target_chat_id
          )

          e

        {:error, reason} = e ->
          Logger.error(
            "Send verification failed: #{inspect(user_id: from_user_id, reason: reason)}",
            chat_id: target_chat_id
          )

          send_text(from_user_id, commands_text("发生了一些未预料的情况，请向开发者反馈。"), logging: true)

          e
      end
    else
      send_text(from_user_id, commands_text("您没有该目标群组的待验证记录。"), logging: true)
    end
  end

  # 响应未知参数
  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_text(chat_id, commands_text("很抱歉，我未能理解您的意图。"), logging: true)
  end
end
