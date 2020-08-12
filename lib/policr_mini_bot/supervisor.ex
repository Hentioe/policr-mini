defmodule PolicrMiniBot.Supervisor do
  @moduledoc false

  use Supervisor

  alias PolicrMiniBot.{
    TakeoverCheckPreheater,
    FromCheckPreheater,
    StartCommander,
    PingCommander,
    SyncCommander,
    LoginCommander,
    SelfJoinedHandler,
    SelfLeftedHandler,
    UserLeftedHandler,
    UserJoinedHandler,
    NewChatTitleHandler,
    NewChatPhotoHandler,
    VerificationCaller,
    RevokeTokenCaller
  }

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    install_plugs([TakeoverCheckPreheater, FromCheckPreheater])
    install_plugs([StartCommander, PingCommander, SyncCommander, LoginCommander])

    install_plugs([
      SelfJoinedHandler,
      SelfLeftedHandler,
      UserLeftedHandler,
      UserJoinedHandler,
      NewChatTitleHandler,
      NewChatPhotoHandler
    ])

    install_plugs([VerificationCaller, RevokeTokenCaller])

    children = [
      # 图片供应服务
      PolicrMiniBot.ImageProvider,
      # 消息清理服务
      PolicrMiniBot.Cleaner,
      # 拉取更新消息
      PolicrMiniBot.UpdatesPoller,
      # 消费消息的动态主管
      PolicrMiniBot.Consumer,
      # 任务调度服务
      PolicrMiniBot.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end

  defp install_plugs(plugs) do
    Telegex.Plug.Pipeline.install_all(plugs)
  end
end
