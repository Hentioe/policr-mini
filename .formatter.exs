[
  import_deps: [:ecto, :phoenix, :ecto_enum, :typed_struct],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test,benches}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
