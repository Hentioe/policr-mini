defmodule Mix.Tasks.Env.Start do
  @moduledoc false

  use Mix.Task

  @impl true
  def run(args) do
    fname = filename(args)

    if file_exists?(fname) do
      exec_docker_compose(fname)
    else
      print_error("File not found: #{fname}")
    end
  end

  defp exec_docker_compose(filename) do
    # 执行外部程序，并实时输出外部程序的所有类型的输出（包括 stderr）
    System.cmd("docker", ["compose", "-f", filename, "up", "-d"], into: IO.stream(:stdio, :line))
  end

  defp filename([prefix]) do
    "#{prefix}.docker-compose.yml"
  end

  defp filename([]), do: "docker-compose.yml"

  defp file_exists?(filename) do
    File.exists?(filename)
  end

  defp print_error(message), do: IO.puts(IO.ANSI.red() <> IO.ANSI.bright() <> message)
end
