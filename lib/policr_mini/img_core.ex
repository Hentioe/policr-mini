defmodule PolicrMini.ImgCore do
  @moduledoc false

  use Rustler, otp_app: :policr_mini, crate: "imgcore"

  # TODO: 缺乏 benchmark，需要以实际图片尺寸为基准进行测试。

  # When your NIF is loaded, it will override this function.
  def rewrite_image(_image, _output_dir), do: :erlang.nif_error(:nif_not_loaded)
end
