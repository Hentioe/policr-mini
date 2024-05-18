defmodule PolicrMiniBot.Supervisor do
  @moduledoc false

  use Supervisor

  require Logger

  def start_link(opts) do
    if Keyword.get(opts, :serve, false) do
      Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    else
      Logger.warning("Bot is not serving")

      :ignore
    end
  end

  @impl true
  def init(_init_arg) do
    # 初始化 workers。
    PolicrMiniBot.Worker.VerificationTerminator.init_queue()

    children = [
      # 任务缓存
      PolicrMiniBot.Worker.JobCacher,
      # 图片提供服务
      PolicrMiniBot.ImageProvider,
      # 验证入口维护器（过时）
      PolicrMiniBot.EntryMaintainer,
      # 一次性处理保证
      PolicrMiniBot.Disposable,
      # 速度限制。
      PolicrMiniBot.SpeedLimiter,
      # 任务调度服务
      PolicrMiniBot.Scheduler,
      # 加群请求托管。
      PolicrMiniBot.JoinReuquestHosting,
      # 消息清理的 Honeycomb 系统
      {Honeycomb, queen: PolicrMiniBot.CleanerQueen},
      # 消息发送的 Honeycomb 系统
      {Honeycomb, queen: PolicrMiniBot.SenderQueen},
      # 入口消息的 Honeycomb 系统
      {Honeycomb, queen: PolicrMiniBot.EntryQueen},
      # 入口管理器的进程注册表
      {Registry, keys: :unique, name: PolicrMiniBot.Entry.Manager.Registry},
      # 入口管理器
      PolicrMiniBot.Entry.Manager,
      # 更新处理器（兼容两个模式）
      updates_handler()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end

  def updates_handler do
    if PolicrMiniBot.config_get(:work_mode) == :webhook do
      PolicrMiniBot.UpdatesAngler
    else
      PolicrMiniBot.UpdatesPoller
    end
  end
end
