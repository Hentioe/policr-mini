defmodule PolicrMini.BuildtimeRuntime do
  @moduledoc false

  defmodule Tools do
    @doc """
    获取构建/运行时信息的工具集。
    """

    @spec erts_version :: String.t()
    def erts_version do
      :version |> :erlang.system_info() |> to_string()
    end

    @spec otp_version :: String.t()
    def otp_version do
      case [:code.root_dir(), "releases", :erlang.system_info(:otp_release), "OTP_VERSION"]
           |> Path.join()
           |> File.read() do
        {:ok, version_text} ->
          String.trim(version_text)

        _ ->
          "unknown"
      end
    end

    defdelegate elixir_version, to: System, as: :version
  end
end
