# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :policr_mini,
  # 通过空格间隔的可选项配置列表
  opts: String.split(System.get_env("POLICR_MINI_OPTS", ""))

database_url =
  System.get_env("POLICR_MINI_DATABASE_URL") ||
    raise """
    environment variable `POLICR_MINI_DATABASE_URL` is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :policr_mini, PolicrMini.Repo,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POLICR_MINI_DATABASE_POOL_SIZE") || "10"),
  migration_timestamps: [type: :utc_datetime]

secret_key_base =
  System.get_env("POLICR_MINI_SERVER_SECRET_KEY_BASE") ||
    raise """
    environment variable `POLICR_MINI_SERVER_SECRET_KEY_BASE` is missing.
    You can generate one by calling: mix phx.gen.secret
    """

# 配置 InfluxDB 连接
config :policr_mini, PolicrMini.InfluxConn,
  auth: [method: :token, token: System.get_env("POLICR_MINI_INFLUX_TOKEN")],
  bucket: System.get_env("POLICR_MINI_INFLUX_BUCKET") || "policr_mini_prod",
  org: System.get_env("POLICR_MINI_INFLUX_ORG") || "policr_mini",
  host: System.get_env("POLICR_MINI_INFLUX_HOST"),
  version: :v2

config :policr_mini, PolicrMiniWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("POLICR_MINI_SERVER_PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

unban_method =
  case System.get_env("POLICR_MINI_UNBAN_METHOD") do
    "until_date" ->
      :until_date

    "api_call" ->
      :api_call

    other ->
      raise """
      Unknown value of variable POLICR_MINI_UNBAN_METHOD: #{other}
      """
  end

# 配置机器人。
config :policr_mini, PolicrMiniBot,
  # 工作模式。
  work_mode: String.to_atom(System.get_env("POLICR_MINI_BOT_WORK_MODE") || "polling"),
  # 是否自动生成命令。
  auto_gen_commands:
    String.to_existing_atom(System.get_env("POLICR_MINI_BOT_AUTO_GEN_COMMANDS") || "false"),
  # 马赛克方法。
  mosaic_method:
    String.to_existing_atom(System.get_env("POLICR_MINI_BOT_MOSAIC_METHOD") || "spoiler"),
  # 拥有者 ID。
  owner_id:
    String.to_integer(
      System.get_env("POLICR_MINI_BOT_OWNER_ID") ||
        raise("""
        environment variable `POLICR_MINI_BOT_OWNER_ID` is missing.
        """)
    ),
  # 机器人名称（用于显示）。
  name: System.get_env("POLICR_MINI_BOT_NAME"),
  # 解封方法。
  unban_method: unban_method

# 配置 Webhook。
config :policr_mini, PolicrMiniBot.UpdatesAngler,
  # Webhook URL。
  webhook_url: System.get_env("POLICR_MINI_BOT_WEBHOOK_URL"),
  # Webhook 服务器端口。
  server_port: String.to_integer(System.get_env("POLICR_MINI_BOT_WEBHOOK_SERVER_PORT") || "4001")

# 配置根链接
config :policr_mini, PolicrMiniWeb,
  root_url:
    System.get_env("POLICR_MINI_SERVER_ROOT_URL") ||
      raise("""
      environment variable `POLICR_MINI_SERVER_ROOT_URL` is missing.
      """)

# Configures the image provider
config :policr_mini, PolicrMiniBot.ImageProvider,
  root:
    System.get_env("POLICR_MINI_BOT_ASSETS_PATH") ||
      raise("""
      environment variable `POLICR_MINI_BOT_ASSETS_PATH` is missing.
      """)

# 配置网格验证。
config :policr_mini, PolicrMiniBot.GridCAPTCHA,
  # 个体图片宽度
  indi_width:
    String.to_integer(System.get_env("POLICR_MINI_BOT_GRID_CAPTCHA_INDI_WIDTH") || "180"),
  # 个体图片高度
  indi_height:
    String.to_integer(System.get_env("POLICR_MINI_BOT_GRID_CAPTCHA_INDI_HEIGHT") || "120"),
  # 个体图片高度
  watermark_font_family:
    System.get_env("POLICR_MINI_BOT_GRID_CAPTCHA_WATERMARK_FONT_FAMILY") || "Lato"

# 配置 Telegex 全局选项。
config :telegex,
  token:
    System.get_env("POLICR_MINI_BOT_TOKEN") ||
      raise("""
      environment variable `POLICR_MINI_BOT_TOKEN` is missing.
      """),
  api_base_url: System.get_env("POLICR_MINI_BOT_API_BASE_URL") || "https://api.telegram.org"

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :policr_mini, PolicrMiniWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
