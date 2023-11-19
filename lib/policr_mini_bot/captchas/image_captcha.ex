defmodule PolicrMiniBot.ImageCAPTCHA do
  @moduledoc """
  图片验证。
  """

  use PolicrMiniBot.Captcha

  alias PolicrMini.ImgCore
  alias PolicrMiniBot.ImageProvider

  defmodule Error do
    defexception [:message]
  end

  @errmsg "There are not enough albums, please try to increase the number of albums or reduce their reference relationship"

  @impl true
  def make!(_chat_id, scheme) do
    count = scheme.image_answers_count || PolicrMiniBot.Helper.default!(:acimage)
    # 获得指定数量的随机图片。
    images = ImageProvider.random_images(count)
    # 检查图片数量是否充足。
    if length(images) < count, do: raise(Error, @errmsg)
    # 生成正确索引。
    correct_index = Enum.random(1..count)
    # 生成候选数据。
    candidates = Enum.map(images, fn image -> [image.name.zh_hans] end)
    # 获取正确索引位置的图片。
    correct_image = Enum.at(images, correct_index - 1)
    # TODO: 在 `ImageProver` 启动时检查目录是否存在，不存在则创建。
    target_dir = Path.join(ImageProvider.root(), "_cache")
    :ok = File.mkdir_p(target_dir)
    # 重写并获取输出图片。
    {:ok, photo} = ImgCore.rewrite_image(correct_image.path, target_dir)

    %Captcha.Data{
      question: "图片中的事物是？",
      photo: photo,
      candidates: candidates,
      correct_indices: [correct_index]
    }
  end
end
