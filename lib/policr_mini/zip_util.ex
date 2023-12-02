defmodule PolicrMini.ZipUtil do
  @moduledoc false

  use Rustler, otp_app: :policr_mini, crate: "ziputil"

  @spec unzip_file(Path.t(), Path.t()) :: {:ok, {}} | {:error, atom}
  def unzip_file(_zip_file, _output_dir), do: :erlang.nif_error(:nif_not_loaded)
end
