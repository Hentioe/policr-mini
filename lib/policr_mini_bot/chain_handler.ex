defmodule PolicrMiniBot.ChainHandler do
  @moduledoc false

  use Telegex.Chain.Handler

  pipeline([
    # 初始化发送来源
    PolicrMiniBot.InitSendSourceChain,
    # 初始化接管状态
    PolicrMiniBot.InitTakenOverChain
  ])
end
