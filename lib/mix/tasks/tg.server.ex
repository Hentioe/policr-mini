defmodule Mix.Tasks.Tg.Server do
  use Mix.Task

  @require_opts [runtime_migrate: true, tg_serve: true]

  @impl true
  def run(args) do
    app_config = Application.get_env(:policr_mini, PolicrMini.Application) || []

    Application.put_env(
      :policr_mini,
      PolicrMini.Application,
      Keyword.merge(app_config, @require_opts)
    )

    Mix.Tasks.Run.run(args ++ run_args())
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end
end
