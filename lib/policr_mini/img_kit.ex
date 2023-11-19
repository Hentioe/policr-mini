defmodule PolicrMini.ImgKit do
  @moduledoc false

  use Rustler, otp_app: :policr_mini, crate: "imgkit"

  # When your NIF is loaded, it will override this function.
  def rewrite_image(_image, _output_dir), do: :erlang.nif_error(:nif_not_loaded)
end
