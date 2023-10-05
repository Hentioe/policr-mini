defmodule PolicrMiniBot.CallRevokeTokenChain do
  @moduledoc """
  回调吊销登录令牌按钮。
  """

  use PolicrMiniBot.Chain, {:callback_query, prefix: "revoke:"}

  alias PolicrMini.UserBusiness

  @impl true
  def handle(%{data: data} = callback_query, context) do
    data |> parse_callback_data() |> _handle(callback_query, context)
  end

  def _handle({"v1", [user_id]}, callback_query, context) do
    %{message: %{chat: %{id: chat_id}, message_id: message_id}} = callback_query
    user_id = String.to_integer(user_id)

    if UserBusiness.upgrade_token_ver(user_id) do
      utc_now = DateTime.utc_now()
      datetime = utc_now |> DateTime.truncate(:second) |> to_string()

      text = commands_text("已成功吊销自 %{datetime} 之前的全部令牌。", %{datetime: "`#{datetime}`"})

      edit_text(chat_id, message_id, text, parse_mode: "MarkdownV2", logging: true)

      {:stop, context}
    else
      send_text(chat_id, commands_text("出于某些原因吊销操作未实际执行，请尝试联系社区群寻求帮助。"), logging: true)

      {:stop, context}
    end
  end
end
