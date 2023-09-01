defmodule PolicrMini.MixProject do
  use Mix.Project

  def project do
    [
      app: :policr_mini,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer()
    ]
  end

  def dialyzer do
    [
      plt_add_apps: [:mnesia, :iex, :mix]
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
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:telegex, git: "https://github.com/Hentioe/telegex.git", branch: "api_5.4-dev"},
      {:telegex_plug, "~> 0.3"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.2"},
      {:postgrex, "~> 0.17"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_enum, "~> 1.4"},
      {:typed_struct, "~> 0.2"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:cors_plug, "~> 3.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 0.5"},
      {:gettext, "~> 0.22"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:quantum, "~> 3.5"},
      {:honeydew, "~> 1.5"},
      {:cachex, "~> 3.6"},
      {:httpoison, "~> 1.8"},
      {:casex, "~> 0.4"},
      {:earmark, "~> 1.4"},
      {:uuid, "~> 2.0", hex: :uuid_erl},
      {:not_qwerty123, "~> 2.3"},
      {:yaml_elixir, "~> 2.7"},
      {:unzip, "~> 0.8"},
      {:mime, "~> 2.0"},
      # TODO: 使用 Telegex 1.0+ 以后（HTTP 客户端改为 Finch），此依赖将会移除。
      {:ssl_verify_fun, "~> 1.1", override: true}
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
