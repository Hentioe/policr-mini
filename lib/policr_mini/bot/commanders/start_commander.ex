defmodule PolicrMini.Bot.StartCommander do
  @moduledoc """
  `/start` 命令的响应模块。
  与其它命令不同，`/start` 命令不需要完整匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。
  这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。
  """
  use PolicrMini.Bot.Commander, :start

  require Logger

  alias PolicrMini.{VerificationBusiness, SchemeBusiness, MessageSnapshotBusiness}
  alias PolicrMini.Schema.Verification
  alias PolicrMini.Bot.{ArithmeticCaptcha, FallbackCaptcha}

  @fallback_captcha_module FallbackCaptcha

  @captchas_maping [
    arithmetic: ArithmeticCaptcha,
    # 当前的备用验证就是主动验证
    initiative: FallbackCaptcha
  ]

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
      send_message(chat_id, t("start.response"))
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
  def handle_args(["verification", "v1", target_chat_id], %{chat: %{id: from_user_id}} = message) do
    target_chat_id = target_chat_id |> String.to_integer()

    if verification = VerificationBusiness.find_unity_waiting(target_chat_id, from_user_id) do
      # 读取验证方案（当前的实现没有实际根据方案数据动态决定什么）
      {:ok, scheme} = SchemeBusiness.fetch(target_chat_id)
      mode = scheme.verification_mode || default!(:vmode)

      captcha_module = @captchas_maping[mode] || @fallback_captcha_module

      # 发送验证消息
      captcha_data =
        try do
          captcha_module.make!()
        rescue
          e ->
            Logger.error(
              "An error occurred in the verification data generation of group `#{target_chat_id}`, fallback to alternatives. Details: #{
                inspect(e)
              }"
            )

            @fallback_captcha_module.make!()
        end

      text =
        "请确认问题并选择您认为正确的答案。\n\n#{captcha_data.question}\n\n您还剩 #{time_left(verification)} 秒，通过可解除封印。"

      markup = PolicrMini.Bot.Captcha.build_markup(captcha_data.candidates, verification.id)

      {:ok, sended_verifiction_message} = send_message(from_user_id, text, reply_markup: markup)

      # 创建消息快照
      {:ok, message_snapshot} =
        MessageSnapshotBusiness.create(%{
          chat_id: target_chat_id,
          message_id: sended_verifiction_message.message_id,
          from_user_id: from_user_id,
          from_user_name: fullname(message.from),
          date: sended_verifiction_message.date,
          text: sended_verifiction_message.text,
          markup_body: Jason.encode!(markup, pretty: false)
        })

      # 更新验证记录：关联消息快照、存储正确答案
      {:ok, _} =
        verification
        |> VerificationBusiness.update(%{
          message_snapshot_id: message_snapshot.id,
          indices: captcha_data.correct_indices
        })
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
  根据验证记录计算剩余时间
  """
  @spec time_left(Verification.t()) :: integer()
  def time_left(%Verification{seconds: seconds, inserted_at: inserted_at}) do
    seconds - DateTime.diff(DateTime.utc_now(), inserted_at)
  end
end
