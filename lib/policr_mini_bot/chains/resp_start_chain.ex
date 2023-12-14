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

  # 重写匹配规则，消息文本以 `/start` 开始的私聊消息即匹配。
  @impl true
  def match?(%{text: text, chat: %{type: "private"}}, _context) when text != nil do
    String.starts_with?(text, @command)
  end

  # 其余皆忽略。
  @impl true
  def match?(_message, _context), do: false

  # 处理携带参数。
  @impl true
  def handle(%{text: <<@command <> " " <> args_text::binary>>} = message, context) do
    args_text
    |> String.trim()
    |> String.split("_")
    |> handle_args(message)

    {:stop, context}
  end

  # 处理空参数。
  @impl true
  def handle(%{chat: chat} = _message, context) do
    theader = commands_text("您好，我是一个专注于新成员验证的机器人。")
    tdesc = commands_text("我具有稳定的服务，便于操作的网页后台。并不断增强与优化的核心功能，保持长期维护。同时我是开源的，可自由复制部署的。")

    tfooter =
      commands_text("访问 %{here_link} 更加了解一下我吧～",
        here_link: ~s|<a href="https://github.com/Hentioe/policr-mini">这里</a>|
      )

    text = """
    #{theader}

    #{tdesc}

    #{tfooter}
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

  # 处理 v1 版本的验证参数。
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = _message) do
    target_chat_id = String.to_integer(target_chat_id)

    if v = Chats.find_pending_verification(target_chat_id, from_user_id) do
      scheme = Chats.find_or_init_scheme!(target_chat_id)
      # 自增发送次数。
      update_params = %{send_times: v.send_times + 1}

      with {:ok, _} <- send_verification(v, scheme),
           {:ok, _v} <- Chats.update_verification(v, update_params) do
        :ok
      else
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

  # 响应未知参数。
  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_text(chat_id, commands_text("很抱歉，我未能理解您的意图。"), logging: true)
  end
end
