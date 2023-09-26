defmodule PolicrMiniBot.InitTakenOverChain do
  @moduledoc """
  在上下文中初始化接管状态。
  """

  use PolicrMiniBot.Chain

  alias PolicrMini.Instances.Chat

  # 当前此函数仅支持了对新消息和回调的来源数据检查，暂不支持其它消息类型。
  # TODO: 针对来自用户的消息进行单独匹配处理，忽略查询以节省性能。
  @impl true
  def handle(_update, %{chat_id: chat_id} = context) do
    taken_over =
      case Chat.get(chat_id) do
        {:ok, chat} -> chat.is_take_over
        _ -> false
      end

    # TODO: [更新前] 批量重命名 `takeovered` 为此处的 `taken_over`。
    {:ok, %{context | taken_over: taken_over}}
  end
end
