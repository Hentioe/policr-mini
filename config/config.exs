# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :policr_mini,
  ecto_repos: [PolicrMini.Repo],
  opts: []

# Configures the endpoint
config :policr_mini, PolicrMiniWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wq9hprszCaMJSjc7N5Fn82z6H/mmuRRSFRu8kfgmBYAoUO9WVoGfAw0gOChFYM1d",
  render_errors: [view: PolicrMiniWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PolicrMini.PubSub,
  live_view: [signing_salt: "hy+GpqGC"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :policr_mini, PolicrMini.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# 配置网格验证
config :policr_mini, PolicrMiniBot.GridCAPTCHA,
  # 个体图片宽度
  indi_width: 180,
  # 个体图片高度
  indi_height: 120,
  # 水印字体
  watermark_font_family: "Lato"

# 配置机器人
config :policr_mini, PolicrMiniBot,
  auto_gen_commands: false,
  mosaic_method: :spoiler

# 配置 Telegex 的适配器
config :telegex,
  caller_adapter: {Finch, [receive_timeout: 5 * 1000]},
  hook_adapter: Cowboy

# 配置根链接
config :policr_mini, PolicrMiniWeb, root_url: "http://0.0.0.0:4000/"

# 配置 Capinde
config :policr_mini, Capinde, base_url: "http://localhost:8080"

# 任务调度配置
config :policr_mini, PolicrMiniBot.Scheduler,
  jobs: [
    # 修正过期验证，每 5 分钟。
    expired_check: [
      schedule: "*/5 * * * *",
      task: {PolicrMiniBot.Runner.ExpiredFixer, :run, []}
    ],
    # 工作状态检查，每 4 小时。todo: 待移除。
    # working_check: [
    #   schedule: "0 */4 * * *",
    #   task: {PolicrMiniBot.Runner.WorkingChecker, :run, []}
    # ],
    # 已离开检查，每日。
    left_check: [
      schedule: "@daily",
      task: {PolicrMiniBot.Runner.LeftChecker, :run, []}
    ]
  ]

# 配置默认语言
config :policr_mini, PolicrMiniWeb.Gettext, default_locale: "zh"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:honeycomb, :request_id, :chat_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
