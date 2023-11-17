defmodule PolicrMini.ImgCore do
  @moduledoc false

  use Rustler, otp_app: :policr_mini, crate: "imgcore"

  # When your NIF is loaded, it will override this function.
  def hello(_name), do: :erlang.nif_error(:nif_not_loaded)
end
