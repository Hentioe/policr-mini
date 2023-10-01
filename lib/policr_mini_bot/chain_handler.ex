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
    PolicrMiniBot.HandleGroupUserJoinedChain
  ])
end
