defmodule PolicrMiniBot.RespSponsorshipChain do
  @moduledoc """
  `/sponsorship` 命令，用于告知用户赞助的方式。
  """

  use PolicrMiniBot.Chain, {:command, :sponsorship}

  @impl true
  def handle(%{chat: %{type: "private"}} = message, context) do
    %{chat: %{id: chat_id}} = message

    text = """
    <b>赞助本项目</b>

    感谢支持！如果您想赞助本项目以推进开发进展或增加维护力度，请访问<a href="https://mini.gramlabs.org/sponsorship">此页面</a>获取赞助的转账方式。

    <i>提示：如果您完成转账，请务必通知项目作者。感谢您 ♥️</i>
    """

    {:ok, _} = Telegex.send_message(chat_id, text, parse_mode: "HTML")

    {:ok, context}
  end

  @impl true
  def handle(_message, context) do
    # todo: 提示在私聊中使用，消息自毁。
    {:ok, context}
  end
end
