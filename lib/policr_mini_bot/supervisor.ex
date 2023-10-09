defmodule PolicrMiniBot.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # 初始化 workers。
    PolicrMiniBot.Worker.MessageCleaner.init_queue()
    PolicrMiniBot.Worker.ValidationTerminator.init_queue()

    # 选择更新处理器。
    updates_handler =
      if PolicrMiniBot.config_get(:work_mode) == :webhook do
        PolicrMiniBot.UpdatesAngler
      else
        PolicrMiniBot.UpdatesPoller
      end

    children = [
      # 任务缓存
      PolicrMiniBot.Worker.JobCacher,
      # 图片提供服务
      PolicrMiniBot.ImageProvider,
      # 验证入口维护器
      PolicrMiniBot.EntryMaintainer,
      # 一次性处理保证
      PolicrMiniBot.Disposable,
      # 速度限制。
      PolicrMiniBot.SpeedLimiter,
      # 任务调度服务
      PolicrMiniBot.Scheduler,
      # 加群请求托管。
      PolicrMiniBot.JoinReuquestHosting,
      # 更新处理器（兼容两个模式）。
      updates_handler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end
end
