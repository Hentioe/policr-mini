# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("POLICR_MINI_DATABASE_URL") ||
    raise """
    environment variable POLICR_MINI_DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :policr_mini, PolicrMini.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POLICR_MINI_DATABASE_POOL_SIZE") || "10"),
  migration_timestamps: [type: :utc_datetime]

secret_key_base =
  System.get_env("POLICR_MINI_SERVER_SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :policr_mini, PolicrMiniWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("POLICR_MINI_SERVER_PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  server: true

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :policr_mini, PolicrMiniWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
