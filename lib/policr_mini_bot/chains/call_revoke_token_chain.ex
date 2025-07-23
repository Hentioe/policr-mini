defmodule PolicrMiniBot.CallRevokeTokenChain do
  @moduledoc false

  use PolicrMiniBot.Chain, {:callback_query, prefix: "revoke:"}

  require Logger

  alias PolicrMini.Accounts

  @impl true
  def handle(%{data: data} = callback_query, context) do
    data |> parse_callback_data() |> _handle(callback_query, context)
  end

  def _handle({"v2", ["admin"]}, callback_query, context) do
    %{message: %{message_id: message_id, chat: %{id: chat_id}}} = callback_query

    if Accounts.upgrade_token_ver(context.user_id) do
      text = """
      已成功吊销自此消息编辑时间之前的全部登录令牌。
      """

      edit_text(chat_id, message_id, text, parse_mode: "HTML", logging: true)

      {:stop, context}
    else
      Logger.warning("Revoking admin token failed: #{inspect(user_id: context.user_id)}",
        chat_id: chat_id
      )

      Telegex.answer_callback_query(callback_query.id,
        text: "出于某些原因吊销操作未实际执行，请尝试联系社区群寻求帮助。",
        show_alert: true
      )

      {:stop, context}
    end
  end

  def _handle({"v1", [user_id]}, callback_query, context) do
    %{message: %{chat: %{id: chat_id}, message_id: message_id}} = callback_query
    user_id = String.to_integer(user_id)

    if Accounts.upgrade_token_ver(user_id) do
      utc_now = DateTime.utc_now()
      datetime = utc_now |> DateTime.truncate(:second) |> to_string()

      text = commands_text("已成功吊销自 %{datetime} 之前的全部令牌。", %{datetime: "`#{datetime}`"})

      edit_text(chat_id, message_id, text, parse_mode: "MarkdownV2", logging: true)

      {:stop, context}
    else
      Logger.warning("Revoking login token failed: #{inspect(user_id: context.user_id)}",
        chat_id: chat_id
      )

      Telegex.answer_callback_query(callback_query.id,
        text: "出于某些原因吊销操作未实际执行，请尝试联系社区群寻求帮助。",
        show_alert: true
      )

      {:stop, context}
    end
  end
end
