defmodule PolicrMiniBot.InitFromChain do
  @moduledoc """
  初始化上下文中的来自身份。
  """

  use PolicrMiniBot.Chain

  alias PolicrMini.PermissionBusiness

  # 检查更新内容中的来源信息， 此函数会填充上下文中的 `from_admin` 和 `from_self` 字段。
  # TODO: 针对来自用户的消息进行单独匹配处理，忽略查询以节省性能。
  @impl true
  def handle(_update, %{chat_id: chat_id, user_id: user_id} = context) do
    from_admin = PermissionBusiness.find(chat_id, user_id) != nil
    from_self = user_id == context.bot.id

    context = %{context | from_admin: from_admin, from_self: from_self}

    {:ok, context}
  end
end
