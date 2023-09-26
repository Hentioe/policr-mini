defmodule PolicrMiniBot.ChainHandler do
  @moduledoc false

  use Telegex.Chain.Handler

  pipeline([
    # 初始化发送来源
    PolicrMiniBot.InitSendSourceChain,
    # 初始化接管状态
    PolicrMiniBot.InitTakenOverChain,
    # 初始化来自身份（如：来自管理员、来自自己）
    PolicrMiniBot.InitFromChain,
    # 初始化可能的动作字段值：user_joined`
    PolicrMiniBot.InitUserJoinedActionChain
  ])
end
