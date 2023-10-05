defmodule PolicrMiniBot.ChainHandler do
  @moduledoc false

  use Telegex.Chain.Handler

  pipeline([
    # 初始化发送来源。
    PolicrMiniBot.InitSendSourceChain,
    # 初始化接管状态。
    PolicrMiniBot.InitTakenOverChain,
    # 初始化来自身份（如：来自管理员、来自自己）。
    PolicrMiniBot.InitFromChain,
    # 初始化可能的动作字段值：`user_joined`。
    PolicrMiniBot.InitUserJoinedActionChain,
    # 初始化可能的动作字段值：`chat_join_request`。
    PolicrMiniBot.InitChatJoinRequestActionChain,
    # 响应 `/start` 命令。
    PolicrMiniBot.RespStartChain,
    # 响应 `/ping` 命令。
    PolicrMiniBot.RespPingChain,
    # 响应 `/sync` 命令。
    PolicrMiniBot.RespSyncChain,
    # 响应 `/login` 命令。
    PolicrMiniBot.RespLoginChain,
    # 响应 `/sponsorship` 命令。
    PolicrMiniBot.RespSponsorshipChain,
    # 响应 `/embarrass_member` 命令。
    PolicrMiniBot.RespEmbarrassMemberChain,
    # 处理加入请求。
    PolicrMiniBot.HandleJoinRequestChain,
    # 处理用户已加入群组。
    PolicrMiniBot.HandleGroupUserJoinedChain,
    # 处理群成员离开。
    PolicrMiniBot.HandleGroupMemberLeftChain,
    # 处理离开消息。
    PolicrMiniBot.HandleLeftMessageChain,
    # 处理自身加入。
    PolicrMiniBot.HandleSelfJoinedChain,
    # 处理自身离开。
    PolicrMiniBot.HandleSelfLeftChain,
    # 处理管理员权限变更。
    # ↓此模块↓ 需保证位于 `PolicrMiniBot.HandleGroupMemberLeftChain` 模块的后面。
    PolicrMiniBot.HandleAdminPermissionsChangeChain,
    # 处理自身权限变更。
    # ↓此模块↓ 需保证位于 `PolicrMiniBot.HandleSelfLeftChain` 模块的后面。
    PolicrMiniBot.HandleSelfPermissionsChangeChain,
    # 处理加入消息。
    PolicrMiniBot.HandleJoinedMessageChain,
    # 处理新的群标题。
    PolicrMiniBot.HandleNewChatTitleChain,
    # 处理新的群头像。
    PolicrMiniBot.HandleNewChatPhotoChain,
    # 处理成员被移除。
    PolicrMiniBot.HandleMemberRemovedChain,
    # 处理私聊附件。
    PolicrMiniBot.HandlePrivateAttachmentChain,
    # 回调验证答案按钮。
    PolicrMiniBot.CallAnswerChain,
    # 回调吊销登录令牌按钮。
    PolicrMiniBot.CallRevokeTokenChain,
    # 回调启用验证按钮。
    PolicrMiniBot.CallEnableChain,
    # 回调离开群组按钮。
    PolicrMiniBot.CallLeaveChain
  ])
end
