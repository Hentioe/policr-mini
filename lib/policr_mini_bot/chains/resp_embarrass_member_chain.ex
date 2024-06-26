defmodule PolicrMiniBot.RespEmbarrassMemberChain do
  @moduledoc """
  `/embarrass_member` 命令。
  """

  use PolicrMiniBot.Chain, {:command, :embarrass_member}

  alias PolicrMini.Chats

  import PolicrMiniBot.VerificationHelper

  require Logger

  @impl true
  def handle(message, %{from_admin: from_admin} = context) when from_admin != true do
    # 无权限，直接删除命令消息
    async_delete_message(message.chat.id, message.message_id)

    {:ok, context}
  end

  @impl true
  def handle(%{reply_to_message: nil} = message, context) do
    send_text(message.chat.id, commands_text("用法错误，请用此命令回复普通群成员的消息。"),
      reply_to_message_id: message.message_id,
      logging: true
    )

    {:ok, context}
  end

  @impl true
  def handle(%{reply_to_message: %{from: %{is_bot: true}}} = message, context) do
    send_text(message.chat.id, commands_text("验证机器人帐号是没有意义的。"),
      reply_to_message_id: message.message_id,
      logging: true
    )

    {:ok, context}
  end

  @impl true
  def handle(%{reply_to_message: reply_to_message} = message, context) do
    target_user = reply_to_message.from

    case Chats.find_user_permission(message.chat.id, target_user.id) do
      nil ->
        # 因为不需要考虑过期和来源等问题，所以直接调用 `embarrass_joined_user/3` 而不是 `embarrass_user/4`
        embarrass_joined_user(message.chat.id, reply_to_message.from)

      _ ->
        send_text(message.chat.id, commands_text("无法对拥有管理权限的人实施验证。"),
          reply_to_message_id: message.message_id,
          logging: true
        )
    end

    {:ok, context}
  end
end
