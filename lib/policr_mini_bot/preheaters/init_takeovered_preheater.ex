defmodule PolicrMiniBot.InitTakeoveredPreheater do
  @moduledoc """
  检查接管状态的预热器。
  """

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.ChatBusiness

  @doc """
  检查更新内容涉及群组的接管状态，填充状态中的相关字段。

  此函数会填充 `PolicrMiniBot.State` 结构中的 `takeovered` 字段。
  当前此函数只支持了对新消息和回调的相关数据检查，暂时没有对其它消息类型进行支持。
  """
  @impl true
  def call(update, state) do
    if chat_id = find_chat_id(update) do
      takeovered =
        case ChatBusiness.get(chat_id) do
          {:ok, chat} -> chat.is_take_over
          _ -> false
        end

      {:ok, %{state | takeovered: takeovered}}
    else
      {:ok, state}
    end
  end

  @spec find_chat_id(Update.t()) :: integer() | nil
  defp find_chat_id(update) do
    cond do
      update.message != nil ->
        %{chat: %{id: chat_id}} = update.message

        chat_id

      update.callback_query != nil ->
        %{message: %{chat: %{id: chat_id}}} = update.callback_query

        chat_id

      update.chat_member != nil ->
        %{chat: %{id: chat_id}} = update.chat_member

        chat_id

      # 注意：未来此处可能要补充对数据的匹配
      true ->
        nil
    end
  end
end
