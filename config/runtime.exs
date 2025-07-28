import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/policr_mini start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.

if System.get_env("PHX_SERVER") do
  config :policr_mini, PolicrMiniWeb.Endpoint, server: true
end

if System.get_env("BOT_SERVER") do
  config :policr_mini, PolicrMini.Application, bot_serve: true
end

if config_env() == :prod do
  config :policr_mini,
    # 读取可选项
    opts: String.split(System.get_env("POLICR_MINI_OPTS", ""))

  database_url =
    System.get_env("POLICR_MINI_DATABASE_URL") ||
      raise """
      environment variable POLICR_MINI_DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  pool_size =
    if size = System.get_env("POLICR_MINI_DATABASE_POOL_SIZE") do
      size != "" && String.to_integer(size)
    end

  config :policr_mini, PolicrMini.Repo,
    url: database_url,
    pool_size: pool_size || 10,
    migration_timestamps: [type: :utc_datetime],
    socket_options: maybe_ipv6

  # 配置 InfluxDB
  config :policr_mini, PolicrMini.InfluxConn,
    auth: [method: :token, token: System.get_env("POLICR_MINI_INFLUX_TOKEN")],
    bucket: System.get_env("POLICR_MINI_INFLUX_BUCKET") || "policr_mini_prod",
    org: System.get_env("POLICR_MINI_INFLUX_ORG") || "policr_mini",
    host: System.get_env("POLICR_MINI_INFLUX_HOST"),
    version: :v2

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("POLICR_MINI_WEB_SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :policr_mini, PolicrMiniWeb.Endpoint,
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("POLICR_MINI_WEB_PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # Configuring Plausible analytics integration.
  config :policr_mini, PolicrMini.Plausible,
    domain: System.get_env("POLICR_MINI_PLAUSIBLE_DOMAIN"),
    script_src: System.get_env("POLICR_MINI_PLAUSIBLE_SCRIPT_SRC")

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :policr_mini, PolicrMini.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.

  unban_method =
    case System.get_env("POLICR_MINI_UNBAN_METHOD") do
      default when default in ["until_date", "", nil] ->
        :until_date

      "api_call" ->
        :api_call

      other ->
        raise """
        Unknown value of variable POLICR_MINI_UNBAN_METHOD: #{other}
        """
    end

  # 配置机器人
  config :policr_mini, PolicrMiniBot,
    # 工作模式
    work_mode: String.to_atom(System.get_env("POLICR_MINI_BOT_WORK_MODE") || "polling"),
    # 是否自动生成命令
    auto_gen_commands:
      String.to_existing_atom(System.get_env("POLICR_MINI_BOT_AUTO_GEN_COMMANDS") || "false"),
    # 马赛克方法
    mosaic_method:
      String.to_existing_atom(System.get_env("POLICR_MINI_BOT_MOSAIC_METHOD") || "spoiler"),
    # 拥有者 ID
    owner_id:
      String.to_integer(
        System.get_env("POLICR_MINI_BOT_OWNER_ID") ||
          raise("""
          environment variable `POLICR_MINI_BOT_OWNER_ID` is missing.
          """)
      ),
    # 解封方法
    unban_method: unban_method

  webhook_port =
    if port = System.get_env("POLICR_MINI_BOT_WEBHOOK_SERVER_PORT") do
      port != "" && String.to_integer(port)
    end

  # 配置 Webhook
  config :policr_mini, PolicrMiniBot.UpdatesAngler,
    # Webhook URL
    webhook_url: System.get_env("POLICR_MINI_BOT_WEBHOOK_URL"),
    # Webhook 服务器端口
    server_port: webhook_port || 4001

  # 配置根链接
  config :policr_mini, PolicrMiniWeb,
    root_url:
      System.get_env("POLICR_MINI_WEB_URL_BASE") ||
        raise("""
        environment variable `POLICR_MINI_WEB_URL_BASE` is missing.
        """)

  # 配置 Capinde
  config :policr_mini, Capinde,
    base_url:
      System.get_env("POLICR_MINI_CAPINDE_BASE_URL") ||
        raise("""
        environment variable `POLICR_MINI_CAPINDE_BASE_URL` is missing.
        """)

  # 配置网格验证
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

  # 配置 Telegex 全局选项
  config :telegex,
    token:
      System.get_env("POLICR_MINI_BOT_TOKEN") ||
        raise("""
        environment variable `POLICR_MINI_BOT_TOKEN` is missing.
        """),
    api_base_url: System.get_env("POLICR_MINI_BOT_API_BASE_URL") || "https://api.telegram.org"
end
