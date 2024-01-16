defmodule PolicrMiniBot.CallLeaveChain do
  @moduledoc """
  回调离开群组按钮。
  """

  use PolicrMiniBot.Chain, {:callback_query, prefix: "leave:"}

  @impl true
  def handle(callback_query, %{from_admin: from_admin} = context)
      when from_admin == nil or from_admin == false do
    Telegex.answer_callback_query(callback_query.id, text: "您没有权限～", show_alert: true)

    {:stop, context}
  end

  @impl true
  def handle(%{data: data} = callback_query, context) do
    data |> parse_callback_data() |> _handle(callback_query, context)
  end

  def _handle({"v1", [chat_id]}, callback_query, context) do
    %{message: %{message_id: message_id}} = callback_query

    Telegex.answer_callback_query(callback_query.id)

    Telegex.edit_message_text("本机器人即将退群。", chat_id: chat_id, message_id: message_id)

    Telegex.leave_chat(chat_id)

    {:stop, context}
  end
end
