defmodule PolicrMiniBot.Supervisor do
  @moduledoc false

  use Supervisor

  # alias PolicrMiniBot.{
  #   HandleSelfJoinedPlug,
  #   HandleSelfLeftedPlug,
  #   HandleAdminPermissionsChangePlug,
  #   HandleSelfPermissionsChangePlug,
  #   RespStartCmdPlug,
  #   RespPingCmdPlug,
  #   RespSyncCmdPlug,
  #   RespLoginCmdPlug,
  #   RespSponsorshipCmdPlug,
  #   HandleUserJoinedCleanupPlug,
  #   HandleMemberRemovedPlug,
  #   HandleNewChatTitlePlug,
  #   HandleNewChatPhotoPlug,
  #   HandlePrivateAttachmentPlug,
  #   CallAnswerPlug,
  #   CallRevokeTokenPlug,
  #   CallEnablePlug,
  #   CallLeavePlug
  # }

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # 初始化消息清理任务
    PolicrMiniBot.Worker.MessageCleaner.init_queue()
    PolicrMiniBot.Worker.ValidationTerminator.init_queue()

    # TODO: 此处用于顺序参考，完整的转换为 chains 以后删除这些注释。
    # install_plugs([
    #   PolicrMiniBot.InitChatJoinRequestActionPlug,
    #   RespStartCmdPlug,
    #   RespPingCmdPlug,
    #   RespSyncCmdPlug,
    #   RespLoginCmdPlug,
    #   RespSponsorshipCmdPlug,
    #   # `/embarrass_member` 命令。
    #   PolicrMiniBot.RespEmbarrassMemberCmdPlug,
    #   PolicrMiniBot.HandleJoinRequestPlug,
    #   PolicrMiniBot.HandleGroupUserJoinedPlug,
    #   PolicrMiniBot.HandleGroupMemberLeftPlug,
    #   PolicrMiniBot.HandleGroupMemberLeftMessagePlug,
    #   HandleSelfJoinedPlug,
    #   HandleSelfLeftedPlug,
    #   # ↓此模块↓ 需保证安装在 `HandleGroupMemberLeftPlug` 模块的后面。
    #   HandleAdminPermissionsChangePlug,
    #   # ↓此模块↓ 需保证安装在 `HandleSelfLeftedPlug` 模块的后面。
    #   HandleSelfPermissionsChangePlug,
    #   HandleUserJoinedCleanupPlug,
    #   HandleNewChatTitlePlug,
    #   HandleNewChatPhotoPlug,
    #   HandleMemberRemovedPlug,
    #   HandlePrivateAttachmentPlug,
    #   CallAnswerPlug,
    #   CallRevokeTokenPlug,
    #   CallEnablePlug,
    #   CallLeavePlug
    # ])

    # !注意! 因为以上的验证排除条件，此模块需要保证在填充以上条件的模块的处理流程的后面。
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
      # 拉取更新消息（TODO: 待删除）
      # PolicrMiniBot.UpdatesPoller,
      # 消费消息的动态主管（TODO: 待删除）
      # PolicrMiniBot.Consumer,
      # 轮询处理器（接收更新并回调处理函数）
      PolicrMiniBot.PollingHandler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end
end
