# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :policr_mini,
  ecto_repos: [PolicrMini.Repo]

# Configures the endpoint
config :policr_mini, PolicrMiniWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wq9hprszCaMJSjc7N5Fn82z6H/mmuRRSFRu8kfgmBYAoUO9WVoGfAw0gOChFYM1d",
  render_errors: [view: PolicrMiniWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PolicrMini.PubSub,
  live_view: [signing_salt: "hy+GpqGC"]

# 配置图片服务。
config :policr_mini, PolicrMiniBot.ImageProvider, root: "_assets"

# 配置机器人。
config :policr_mini, PolicrMiniBot, auto_gen_commands: false, opts: []

# 配置 Telegex 的适配器。
config :telegex,
  # HTTP 客户端。
  caller_adapter: {Finch, [receive_timeout: 5 * 1000]},
  # Webhook 服务端。
  hook_adapter: Cowboy

# 配置根链接。
config :policr_mini, PolicrMiniWeb, root_url: "http://0.0.0.0:4000/"

# 任务调度配置。
config :policr_mini, PolicrMiniBot.Scheduler,
  jobs: [
    # 修正过期验证，每 5 分钟。
    expired_check: [
      schedule: "*/5 * * * *",
      task: {PolicrMiniBot.Runner.ExpiredChecker, :run, []}
    ],
    # 工作状态检查，每 4 小时。
    working_check: [
      schedule: "0 */4 * * *",
      task: {PolicrMiniBot.Runner.WorkingChecker, :run, []}
    ],
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
  metadata: [:request_id, :chat_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
