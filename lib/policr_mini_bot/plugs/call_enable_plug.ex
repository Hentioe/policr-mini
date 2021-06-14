defmodule PolicrMiniBot.CallEnablePlug do
  @moduledoc """
  启用验证功能的回调。
  """

  use PolicrMiniBot, plug: [caller: [prefix: "enable:"]]

  alias PolicrMini.ChatBusiness

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

    case ChatBusiness.get(chat_id) do
      {:ok, chat} ->
        ChatBusiness.update(chat, %{is_take_over: true})

        Telegex.answer_callback_query(callback_query.id, text: "功能已启用~", show_alert: true)

        Telegex.edit_message_text("<b>本机器人已接管新成员验证。</b>",
          chat_id: chat_id,
          message_id: message_id,
          parse_mode: "HTML"
        )

      _ ->
        Telegex.answer_callback_query(callback_query.id,
          text: "未找到你群数据，试试 /sync 命令？",
          show_alert: true
        )
    end

    :ok
  end
end
