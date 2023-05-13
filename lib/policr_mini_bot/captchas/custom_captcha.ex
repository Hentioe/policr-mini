defmodule PolicrMiniBot.CustomCaptcha do
  @moduledoc """
  生成自定义验证。

  自定义验证的消息类型不是固定的，可能是图片、文字或多图片组。但注意：**当前**此模块仅生成文字消息。
  """

  use PolicrMiniBot.Captcha
  use PolicrMini.I18n

  alias PolicrMini.Chats
  alias PolicrMini.Chats.{Scheme, CustomKit}
  alias PolicrMiniBot.CaptchaMakeFailed

  @impl true
  def make!(chat_id, scheme) do
    _make!(chat_id, scheme, Chats.random_custom_kit(chat_id))
  end

  @spec _make!(binary | integer, Scheme.t(), CustomKit.t() | nil) ::
          Captcha.Data.t()
  def _make!(chat_id, _scheme, nil = _custom_kit) do
    # 自动切换到默认验证（空值）
    Chats.upsert_scheme(chat_id, %{verification_mode: nil})

    # 在群内通知

    ttitle = commands_text("异常提醒")

    tbody = commands_text("由于本群未设置自定义问答内容，已将验证模式从自定义切换为系统默认。")

    tcomment = commands_text("这是一种自我纠错的机制，并不影响验证消息的生成，通常也不会再次出现（短时间内高并发验证除外）。")

    text = """
    <b>#{ttitle}</b>

    #{tbody}

    <i>#{tcomment}</i>
    """

    Telegex.send_message(chat_id, text, parse_mode: "HTML")

    raise CaptchaMakeFailed, message: "No custom kit found"
  end

  def _make!(_chat_id, _scheme, custom_kit) do
    # 随机混乱答案列表
    answers = Enum.shuffle(custom_kit.answers)

    correct_indices =
      answers
      |> Enum.with_index()
      |> Enum.filter(&String.starts_with?(elem(&1, 0), "+"))
      |> Enum.map(fn {_, index} -> index + 1 end)

    candidates = Enum.map(answers, fn ans -> [String.slice(ans, 1..-1)] end)

    %Captcha.Data{
      question: custom_kit.title,
      attachment: custom_kit.attachment,
      candidates: candidates,
      correct_indices: correct_indices
    }
  end
end
