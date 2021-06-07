defmodule PolicrMiniBot.LeaveCaller do
  @moduledoc """
  启用验证功能的回调。
  """

  use PolicrMiniBot, plug: [caller: [prefix: "leave:"]]

  @doc """
  回调处理函数。
  """
  @impl true
  def handle(callback_query, %{from_admin: from_admin} = _state)
      when from_admin == nil or from_admin == false do
    Telegex.answer_callback_query(callback_query.id, text: "您没有权限~", show_alert: true)

    :ok
  end

  @impl true
  def handle(%{data: data} = callback_query, state) do
    data |> parse_callback_data() |> handle(callback_query, state)
  end

  def handle({"v1", [chat_id]}, callback_query, _state) do
    %{message: %{message_id: message_id}} = callback_query

    Telegex.answer_callback_query(callback_query.id)

    Telegex.edit_message_text("本机器人即将退群。", chat_id: chat_id, message_id: message_id)

    Telegex.leave_chat(chat_id)

    :ok
  end
end
