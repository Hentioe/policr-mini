defmodule PolicrMini.MixProject do
  use Mix.Project

  def project do
    [
      app: :policr_mini,
      version: "0.1.0",
      elixir: "~> 1.16",
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
      {:rustler, "~> 0.32.1", runtime: false},
      {:benchee, "~> 1.0", only: :dev},
      {:telegex, git: "https://github.com/Hentioe/telegex.git", branch: "v1.6"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.2"},
      {:postgrex, "~> 0.17"},
      {:ecto_sql, "~> 3.11"},
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
      {:tarams, "~> 1.8"},
      {:plug_cowboy, "~> 2.6"},
      {:remote_ip, "~> 1.1"},
      {:quantum, "~> 3.5"},
      {:honeydew, "~> 1.5"},
      {:cachex, "~> 3.6"},
      {:finch, "~> 0.18.0"},
      {:multipart, "~> 0.4.0"},
      {:casex, "~> 0.4.2"},
      {:earmark, "~> 1.4"},
      {:uuid, "~> 2.0", hex: :uuid_erl},
      {:yaml_elixir, "~> 2.9"},
      {:unzip, "~> 0.11"},
      {:mime, "~> 2.0"},
      {:instream, "~> 2.2"},
      {:figlet, git: "https://github.com/Hentioe/figlet", branch: "compatible_1.16"},
      # 此库依赖 Rust
      {:img_grider, git: "https://github.com/gramlabs-oss/img_grider.git"}
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
