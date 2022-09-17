defmodule PolicrMini.MixProject do
  use Mix.Project

  def project do
    [
      app: :policr_mini,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  def dialyzer do
    [
      plt_add_apps: [:mnesia]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PolicrMini.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:telegex, git: "https://github.com/Hentioe/telegex.git", branch: "api_5.4-dev"},
      {:telegex_marked, "~> 0.0.8"},
      {:telegex_plug, "~> 0.3"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.2"},
      {:postgrex, "~> 0.16"},
      {:ecto_sql, "~> 3.8"},
      {:ecto_enum, "~> 1.4"},
      {:typed_struct, "~> 0.2"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:cors_plug, "~> 2.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:quantum, "~> 3.5"},
      {:honeydew, "~> 1.5"},
      # TODO: 使用 `honeydew` 替代此库功能。
      {:task_after, "~> 1.2"},
      {:cachex, "~> 3.4"},
      {:httpoison, "~> 1.8"},
      # TODO: 使用 `casex` 替代此库功能。
      {:proper_case, "~> 1.3"},
      {:earmark, "~> 1.4"},
      # TODO: 使用 `uuid_erl` 替代此库功能。
      {:elixir_uuid, "~> 1.2"},
      {:not_qwerty123, "~> 2.3"},
      {:yaml_elixir, "~> 2.7"},
      {:unzip, "~> 0.6"},
      {:mime, "~> 1.6"},
      {:exi18n, github: "Hentioe/exi18n"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
