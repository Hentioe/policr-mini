defmodule PolicrMiniBot.CustomCaptcha do
  @moduledoc """
  生成自定义验证。

  自定义验证的消息类型不是固定的，可能是图片、文字或多图片组。但注意：**当前**此模块仅生成文字消息。
  """

  use PolicrMiniBot.Captcha

  alias PolicrMini.CustomKitBusiness

  @impl true
  def make!(chat_id) do
    custom_kit = CustomKitBusiness.random_one(chat_id)

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
      candidates: candidates,
      correct_indices: correct_indices
    }
  end
end
