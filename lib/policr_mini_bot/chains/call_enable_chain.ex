defmodule PolicrMiniBot.CallEnableChain do
  @moduledoc """
  回调启用验证按钮。
  """

  # TODO: 启用功能前添加必要权限的检查。

  use PolicrMiniBot.Chain, {:callback_query, prefix: "enable:"}

  alias PolicrMini.Instances
  alias PolicrMini.Instances.Chat

  @impl true
  def handle(callback_query, %{from_admin: from_admin} = _context)
      when from_admin == nil or from_admin == false do
    Telegex.answer_callback_query(callback_query.id, text: "您没有权限～", show_alert: true)

    :ok
  end

  @impl true
  def handle(%{data: data} = callback_query, context) do
    data |> parse_callback_data() |> _handle(callback_query, context)
  end

  def _handle({"v1", [chat_id]}, callback_query, context) do
    %{message: %{message_id: message_id}} = callback_query

    case Chat.get(chat_id) do
      {:ok, chat} ->
        Instances.update_chat(chat, %{is_take_over: true})

        Telegex.answer_callback_query(callback_query.id, text: "功能已启用～", show_alert: true)

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

    {:stop, context}
  end
end
