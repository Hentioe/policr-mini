defmodule PolicrMini.Bot.ImageCaptcha do
  @moduledoc """
  提供图片验证的模块。
  当前此模块的实现为提供一张图片和包含一个正确答案的三个候选词。
  需要用户识别图片中的内容进行选择。
  """

  use PolicrMini.Bot.Captcha

  @count 3

  @impl true
  def make! do
    series_images = PolicrMini.Bot.ImageProvider.random(@count)

    correct_index = Enum.random(1..3)

    candidates = series_images |> Enum.map(fn si -> [si.name_zh_hans] end)

    correct_series_image = series_images |> Enum.at(correct_index - 1)
    photo = correct_series_image.files |> Enum.random()

    %Captcha.Data{
      question: "图片中的事物是？",
      photo: photo,
      candidates: candidates,
      correct_indices: [correct_index]
    }
  end
end
