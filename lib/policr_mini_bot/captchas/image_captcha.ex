defmodule PolicrMiniBot.ImageCaptcha do
  @moduledoc """
  提供图片验证的模块。
  当前此模块的实现为提供一张图片和包含一个正确答案的三个候选词。
  需要用户识别图片中的内容进行选择。
  """

  use PolicrMiniBot.Captcha

  defmodule Error do
    defexception [:message]
  end

  @count 3

  @impl true
  def make!(_chat_id) do
    # 获得随机数量的系列图片
    series_images = PolicrMiniBot.ImageProvider.random(@count)

    # 检查图片的系列数量是否充足
    if length(series_images) < @count, do: raise(Error, "There are not enough series of images")

    # 生成正确索引
    correct_index = Enum.random(1..@count)

    # 生成候选数据
    candidates = series_images |> Enum.map(fn si -> [si.name_zh_hans] end)

    # 获取正确索引位置的图片
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
