defmodule PolicrMini.Bot.StartCommander do
  @moduledoc """
  `/start` 命令的响应模块。
  与其它命令不同，`/start` 命令不需要完整匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。
  这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。
  """
  use PolicrMini.Bot.Commander, :start

  alias PolicrMini.{VerificationBusiness, SchemeBusiness}
  alias PolicrMini.Schema.{Verification, Scheme}

  @doc """
  重写后的 `match?/1` 函数，以 `/start` 开始即匹配。
  """
  @impl true
  def match?(text), do: text |> String.starts_with?(@command)

  @doc """
  群组消息，忽略。
  """
  @impl true
  def handle(%{chat: %{type: "group"}}, state), do: {:ignored, state}

  @doc """
  群组（超级群）消息，忽略。
  """
  @impl true
  def handle(%{chat: %{type: "supergroup"}}, state), do: {:ignored, state}

  @doc """
  响应命令。
  如果命令没有携带参数，则发送包含链接的项目介绍。否则将参数整体传递给 `dispatch/1` 函数进一步拆分和分发。
  """
  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, text: text} = message

    splited_text = text |> String.split(" ")

    if length(splited_text) == 2 do
      splited_text |> List.last() |> dispatch(message)
    else
      send_message(chat_id, "访问[这里](https://github.com/Hentioe/policr-mini)了解了解我吧～")
    end

    {:ok, state}
  end

  @doc """
  分发命令参数。
  以 `_` 分割成更多参数，转发给 `handle_args/1` 函数处理。
  """
  def dispatch(arg, message), do: arg |> String.split("_") |> handle_args(message)

  @doc """
  处理 v1 版本的验证参数。
  主要进行以下大致流程，按先后顺序：
  1. 读取验证方案
  1. 发送验证消息
  1. 创建消息快照
  1. 更新验证记录
  """
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = _message) do
    target_chat_id = target_chat_id |> String.to_integer()

    if verification = VerificationBusiness.find_unity_waiting(target_chat_id, from_user_id) do
      # 读取验证方案
      {:ok, scheme} = SchemeBusiness.fetch(target_chat_id)

      # 发送验证消息
      {text, markup} = make_verification_message(scheme, verification)
      {:ok, _} = send_message(from_user_id, text, reply_markup: markup)

      # TODO: 创建消息快照

      # TODO: 更新验证记录
    else
      send_message(from_user_id, "您没有该目标群组的待验证记录。")
    end
  end

  @doc """
  响应未知参数。
  """
  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_message(chat_id, "很抱歉，我未能理解您的意图。")
  end

  @doc """
  生成默认模式的验证消息（算数验证）。
  """
  @spec make_verification_message(Scheme.t(), Verification.t()) ::
          {String.t(), InlineKeyboardMarkup.t()}
  def make_verification_message(
        %Scheme{verification_mode: nil},
        %Verification{id: verification_id, chat: %{title: chat_title}} = verification
      ) do
    text = "来自【#{chat_title}】的算术验证题：请选择「1 + 1 = ?」。\n\n您还剩 #{time_left(verification)} 秒，通过可解除封印。"

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        1..3
        |> Enum.map(fn i ->
          %InlineKeyboardButton{
            text: "#{i}",
            callback_data: "verification:v1:#{i}:#{verification_id}"
          }
        end)
      ]
    }

    {text, markup}
  end

  @doc """
  根据验证记录计算剩余时间
  """
  @spec time_left(Verification.t()) :: integer()
  def time_left(%Verification{seconds: seconds, inserted_at: inserted_at}) do
    seconds - DateTime.diff(DateTime.utc_now(), inserted_at)
  end
end
