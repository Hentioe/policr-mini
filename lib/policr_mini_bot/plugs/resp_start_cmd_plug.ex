defmodule PolicrMiniBot.RespStartCmdPlug do
  @moduledoc """
  `/start` 命令。

  与其它命令不同，`/start` 命令不需要保证完整的匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。
  这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。
  """

  use PolicrMiniBot, plug: [commander: :start]

  alias PolicrMini.Chats
  alias Telegex.Model.{Message, InlineKeyboardMarkup, InlineKeyboardButton}

  import PolicrMiniBot.VerificationHelper

  require Logger

  @type captcha_data :: PolicrMiniBot.Captcha.Data.t()
  @type tgerr :: Telegex.Model.errors()
  @type tgmsg :: Telegex.Model.Message.t()

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
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = _message) do
    target_chat_id = target_chat_id |> String.to_integer()

    if verification = Chats.find_pending_verification(target_chat_id, from_user_id) do
      scheme = Chats.find_or_init_scheme!(target_chat_id)

      case send_verification(verification, scheme) do
        {:ok, _} ->
          :ok

        {:error, %{error_code: 403}} = e ->
          Logger.warning(
            "Verification creation failed due to user blocking: #{inspect(user_id: from_user_id)}",
            chat_id: target_chat_id
          )

          e

        {:error, reason} = e ->
          Logger.error(
            "Send verification failed: #{inspect(user_id: from_user_id, reason: reason)}",
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
end
