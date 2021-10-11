defmodule PolicrMiniWeb.Admin.API.SponsorshipAddressController do
  @moduledoc """
  赞助地址的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.Instances
  alias PolicrMini.Instances.SponsorshipAddress

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      sponsorship_addresses = Instances.find_sponsorship_addresses()

      render(conn, "index.json", %{sponsorship_addresses: sponsorship_addresses})
    end
  end

  def add(conn, params) do
    params = processing_image_params(params)

    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_address} <- Instances.create_sponsorship_address(params) do
      render(conn, "sponsorship_address.json", %{sponsorship_address: sponsorship_address})
    end
  end

  def update(conn, %{"id" => id} = params) do
    params = processing_image_params(params)

    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_address} <- SponsorshipAddress.get(id),
         {:ok, sponsorship_address} <-
           Instances.update_sponsorship_address(sponsorship_address, params) do
      render(conn, "sponsorship_address.json", %{sponsorship_address: sponsorship_address})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_address} <- SponsorshipAddress.get(id),
         {:ok, sponsorship_address} <-
           Instances.delete_sponsorship_address(sponsorship_address) do
      render(conn, "sponsorship_address.json", %{sponsorship_address: sponsorship_address})
    end
  end

  # 处理参数中的图片，返回处理后的参数。
  # 将图片复制到上传目录（_uploaded），并根据跟规范命名图片。将重命名后的值写入到 `image` 参数并返回。
  @spec processing_image_params(map) :: map
  defp processing_image_params(%{"image_attach" => image_attach} = params) do
    # TODO: 独立一个处理上传的模块，包括自动创建上传目录。
    uploaded_path = PolicrMiniWeb.uploaded_path()
    if !File.exists?(uploaded_path), do: File.mkdir!(uploaded_path)

    file_path = image_attach.path
    File.exists?(file_path) |> IO.inspect()

    image_name = gen_file_name(file_path, Path.extname(image_attach.filename))
    File.cp!(file_path, Path.join(uploaded_path, image_name))

    Map.put(params, "image", image_name)
  end

  defp processing_image_params(params), do: params

  # TODO: 将此函数迁移到独立的上传功能模块中。
  @doc """
  提供文件路径和扩展名，以摘要信息生成文件名。

  ## 例子：
      iex> PolicrMiniWeb.Admin.API.SponsorshipAddressController.gen_file_name("LICENSE", ".jpg")
      "sponsorship-addresses-4b5c9d5.jpg"
  """
  def gen_file_name(file_path, ext) do
    hash =
      File.stream!(file_path)
      |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
      |> :crypto.hash_final()
      |> Base.encode16()
      |> String.downcase()
      |> String.slice(0..6)

    "sponsorship-addresses-#{hash}#{ext}"
  end
end
