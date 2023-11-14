defmodule PolicrMiniBot.GridCAPTCHA do
  @moduledoc """
  网格验证。
  """

  use PolicrMiniBot.Captcha

  alias PolicrMiniBot.ImageProvider

  defmodule Error do
    defexception [:message]
  end

  @errmsg "There are not enough albums, please try to increase the number of albums or reduce their reference relationship"
  @grid_size 9
  @expected_similar_count 3

  @impl true
  def make!(_chat_id, scheme) do
    # 获取图集列表（等于网格大小）。
    albums = ImageProvider.random_albums(@grid_size)
    # 检查图集数量是否充足。
    if length(albums) < @grid_size, do: raise(Error, @errmsg)
    # 生成一个作为正确答案的图集。
    corrent_album_pos = Enum.random(0..(@grid_size - 1))
    correct_album = Enum.at(albums, corrent_album_pos)
    # 决定包含的正确图片列表。
    corrent_images =
      if length(correct_album.images) < @expected_similar_count do
        # 如果图集中的图片数量不足，则直接使用图集中的所有图片。
        correct_album.images
      else
        # 否则，从图集中随机选择指定数量的图片。
        correct_album.images |> Enum.shuffle() |> Enum.take(@expected_similar_count)
      end

    corrent_images_count = length(corrent_images)
    # 生成随机的「编号-图片」对。
    correct_pairs =
      1..9
      |> Enum.shuffle()
      |> Enum.take(corrent_images_count)
      |> Enum.with_index()
      |> Enum.map(fn {number, index} -> {number, Enum.at(corrent_images, index)} end)

    # 将正确图片按照编号装入一个长度为 9 的图片容器中。
    container = List.duplicate(:empty, 9)

    container =
      Enum.reduce(correct_pairs, container, fn {number, image}, acc ->
        List.replace_at(acc, number - 1, image)
      end)

    # 得到空图片的位置列表。
    empty_pos_list =
      container
      |> Enum.with_index()
      |> Enum.filter(fn {image, _i} -> image == :empty end)
      |> Enum.map(fn {_image, i} -> i end)

    # 用剩余图片填满图片容器。
    other_albums = List.delete_at(albums, corrent_album_pos)

    other_images =
      other_albums |> Enum.map(fn album -> album.images end) |> List.flatten() |> Enum.shuffle()

    {container, _} =
      Enum.reduce(empty_pos_list, {container, other_images}, fn pos, {container, other_images} ->
        {image, other_images} = List.pop_at(other_images, 0)
        container = List.replace_at(container, pos, image)

        {container, other_images}
      end)

    # 正确的候选答案。
    correct_candidate = Enum.map_join(correct_pairs, "", fn {number, _image} -> number end)
    # 生成一个随机的正确答案位置。
    correct_index = Enum.random(1..9)
    # 生成全部候选答案（正确的候选答案将插入到指定位置）。
    candidates =
      correct_candidate
      |> generate_incorrect_candidates()
      |> List.insert_at(correct_index - 1, correct_candidate)

    # 生成网格图片。
    {:ok, photo} = generate_image(Enum.map(container, fn image -> image.path end))

    %Captcha.Data{
      question: "选出所有「#{correct_album.name.zh_hans}」的图片编号",
      photo: photo,
      candidates: Enum.chunk_every(candidates, 3),
      correct_indices: [correct_index]
    }
  end

  @spec generate_incorrect_candidates(String.t(), [String.t()], non_neg_integer()) :: [String.t()]
  defp generate_incorrect_candidates(correct_candidate, incorrect_candidates \\ [], count \\ 0),
    do: _generate_incorrect_candidates(correct_candidate, incorrect_candidates, count)

  # 生成数量达到 8 个，直接返回。
  defp _generate_incorrect_candidates(correct_candidate, incorrect_candidates, count = 8) do
    incorrect_candidates
  end

  defp _generate_incorrect_candidates(correct_candidate, incorrect_candidates, count) do
    ic = 1..9 |> Enum.shuffle() |> Enum.take(3) |> Enum.join()

    cond do
      ic != correct_candidate ->
        _generate_incorrect_candidates(correct_candidate, [ic | incorrect_candidates], count + 1)

      true ->
        # 如果和正确答案重复，重新生成。
        _generate_incorrect_candidates(correct_candidate, incorrect_candidates, count)
    end
  end

  defp generate_image(photos) do
    # TODO: 配置化缓存目录。
    target_dir = Path.join(ImageProvider.root(), "_cache")
    # TODO: 在 `ImageProver` 启动时检查目录是否存在，不存在则创建。
    :ok = File.mkdir_p(target_dir)

    # TODO: 配置化水印字体。
    scheme = %ImgGrider.Scheme{
      target_dir: target_dir,
      indi_width: config_get(:indi_width, 180),
      indi_height: config_get(:indi_height, 120)
    }

    {:ok, path} = ImgGrider.generate(photos, scheme)
  end

  defp config_get(key, default \\ nil) do
    Application.get_env(:policr_mini, __MODULE__)[key] || default
  end
end
