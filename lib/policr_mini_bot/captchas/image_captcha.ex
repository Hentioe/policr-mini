defmodule PolicrMiniBot.ImageCaptcha do
  @moduledoc """
  提供图片验证的模块。

  提供一张图片和包含一个正确答案并生成指定数量的候选答案列表，所有答案皆来自图集资源中的数据。
  需要用户识别图片中的内容进行选择。
  """

  use PolicrMiniBot.Captcha

  defmodule Error do
    defexception [:message]
  end

  @errmsg "There are not enough albums, please try to increase the number of albums or reduce their reference relationship"

  @impl true
  def make!(_chat_id, scheme) do
    count = scheme.image_answers_count || PolicrMiniBot.Helper.default!(:acimage)

    # 获得随机数量的图片。
    images = PolicrMiniBot.ImageProvider.bomb(count)

    # 检查图片的系列数量是否充足
    if length(images) < count, do: raise(Error, @errmsg)

    # 生成正确索引
    correct_index = Enum.random(1..count)

    # 生成候选数据
    candidates = images |> Enum.map(fn image -> [image.name.zh_hans] end)

    # 获取正确索引位置的图片
    correct_image = images |> Enum.at(correct_index - 1)
    photo = correct_image.path

    %Captcha.Data{
      question: "图片中的事物是？",
      photo: photo,
      candidates: candidates,
      correct_indices: [correct_index]
    }
  end
end
