defmodule PolicrMiniBot.CallRevokeTokenPlug do
  @moduledoc """
  处理令牌吊销回调。
  """

  use PolicrMiniBot, plug: [caller: [prefix: "revoke:"]]

  alias PolicrMini.UserBusiness

  @doc """
  回调处理函数。
  """
  @impl true
  def handle(%{data: data} = callback_query, state) do
    data |> parse_callback_data() |> handle(callback_query, state)
  end

  def handle({"v1", [user_id]}, callback_query, _state) do
    %{message: %{chat: %{id: chat_id}, message_id: message_id}} = callback_query
    user_id = String.to_integer(user_id)

    if UserBusiness.upgrade_token_ver(user_id) do
      utc_now = DateTime.utc_now()
      datetime = utc_now |> DateTime.truncate(:second) |> to_string()

      text = t("revoke.success", %{datetime: datetime})

      edit_message_text(text, chat_id: chat_id, message_id: message_id)

      :ok
    else
      text = t("revoke.failed")

      send_message(chat_id, text)

      :error
    end
  end
end
