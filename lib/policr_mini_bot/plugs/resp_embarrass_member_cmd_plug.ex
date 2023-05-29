defmodule PolicrMiniBot.RespEmbarrassMemberCmdPlug do
  @moduledoc """
  /embarrass_member 命令。
  """

  use PolicrMiniBot, plug: [commander: :embarrass_member]

  alias PolicrMini.Chats
  alias PolicrMiniBot.Worker

  import PolicrMiniBot.VerificationHelper

  require Logger

  def handle(message, %{from_admin: from_admin} = state) when from_admin != true do
    # 无权限，直接删除命令消息
    Worker.async_delete_message(message.chat.id, message.message_id)

    {:ok, state}
  end

  def handle(%{reply_to_message: nil} = message, state) do
    send_text(message.chat.id, commands_text("用法错误，请用此命令回复普通群成员的消息。"),
      reply_to_message_id: message.message_id,
      logging: true
    )

    {:ok, state}
  end

  @impl true
  def handle(%{reply_to_message: %{from: %{is_bot: true}}} = message, state) do
    send_text(message.chat.id, commands_text("验证机器人帐号是没有意义的。"),
      reply_to_message_id: message.message_id,
      logging: true
    )

    {:ok, state}
  end

  @impl true
  def handle(%{reply_to_message: reply_to_message} = message, state) do
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

    {:ok, state}
  end
end
