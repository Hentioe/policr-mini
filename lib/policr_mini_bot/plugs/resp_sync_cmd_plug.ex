defmodule PolicrMiniBot.RespSyncCmdPlug do
  @moduledoc """
  `/sync` 命令的响应模块。

  此命令存在速度限制，15 秒内只能调用一次。
  """

  alias PolicrMini.Logger

  use PolicrMiniBot, plug: [commander: :sync]

  alias PolicrMini.{Instances, Chats}
  alias PolicrMini.Instances.Chat
  alias PolicrMiniBot.{SpeedLimiter, Worker}
  alias PolicrMiniBot.Helper.Syncing

  @doc """
  同步群组数据：群组信息、管理员列表。
  """

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, message_id: message_id} = message

    speed_limit_key = "sync-#{chat_id}"

    waiting_sec = SpeedLimiter.get(speed_limit_key)

    cond do
      waiting_sec > 0 ->
        send_message(chat_id, "同步过于频繁，请在 #{waiting_sec} 秒后重试。")

      no_permissions?(message) ->
        # 添加 10 秒的速度限制记录。
        :ok = SpeedLimiter.put(speed_limit_key, 10)

        Worker.async_delete_message(chat_id, message_id)

      true ->
        # 添加 15 秒的速度限制记录。
        :ok = SpeedLimiter.put(speed_limit_key, 15)

        async_run(fn -> typing(chat_id) end)

        # 同步群组和管理员信息，并自动设置接管状态。
        # 注意，同步完成后需进一步确保方案存在。
        with {:ok, chat} <- synchronize_chat(chat_id),
             {:ok, chat} <- Syncing.sync_for_chat_permissions(chat),
             {:ok, _scheme} <- Chats.fetch_scheme(chat_id),
             # 获取自身权限
             {:ok, member} <- Telegex.get_chat_member(chat_id, PolicrMiniBot.id()) do
          is_admin = member.status == "administrator"

          last_is_take_over = chat.is_take_over

          if is_admin do
            Instances.update_chat(chat, %{is_take_over: true})
          else
            Instances.cancel_chat_takeover(chat)
          end

          message_text = t("sync.success")

          message_text =
            if is_admin do
              message_text <>
                t("sync.have_permissions") <>
                if last_is_take_over, do: t("sync.already_takeover"), else: t("sync.has_takeover")
            else
              message_text <>
                t("sync.no_permission") <>
                if(last_is_take_over,
                  do: t("sync.cancelled_takeover"),
                  else: t("sync.unable_takeover")
                )
            end

          async_run(fn -> send_message(chat_id, message_text) end)
        else
          {:error, e} ->
            Logger.unitized_error("Group data synchronization", e)
            send_message(chat_id, t("errors.sync_failed"))
        end
    end

    {:ok, state}
  end

  @doc """
  同步群信息数据。
  """
  @spec synchronize_chat(integer, boolean) :: {:ok, Chat.t()} | {:error, Ecto.Changeset.t()}
  def synchronize_chat(chat_id, init \\ false) do
    case Telegex.get_chat(chat_id) do
      {:ok, chat} ->
        {small_photo_id, big_photo_id} =
          if photo = chat.photo, do: {photo.small_file_id, photo.big_file_id}, else: {nil, nil}

        %{
          type: type,
          title: title,
          username: username,
          description: description,
          permissions: chat_permissions
        } = chat

        params = %{
          type: type,
          title: title,
          small_photo_id: small_photo_id,
          big_photo_id: big_photo_id,
          username: username,
          description: description,
          left: false,
          tg_can_add_web_page_previews: chat_permissions.can_add_web_page_previews,
          tg_can_change_info: chat_permissions.can_change_info,
          tg_can_invite_users: chat_permissions.can_invite_users,
          tg_can_pin_messages: chat_permissions.can_pin_messages,
          tg_can_send_media_messages: chat_permissions.can_send_media_messages,
          tg_can_send_messages: chat_permissions.can_send_messages,
          tg_can_send_other_messages: chat_permissions.can_send_other_messages,
          tg_can_send_polls: chat_permissions.can_send_polls
        }

        params = (init && Map.put(params, :is_take_over, false)) || params

        case Instances.fetch_and_update_chat(chat_id, params) do
          {:error,
           %Ecto.Changeset{errors: [is_take_over: {"can't be blank", [validation: :required]}]}} ->
            Instances.fetch_and_update_chat(chat_id, params |> Map.put(:is_take_over, false))

          r ->
            r
        end

      e ->
        e
    end
  end

  @group_annonymous_bot_id 1_087_968_824

  # 检查消息来源是否具备权限。
  # 如果是匿名用户，会被视为无权限。
  defp no_permissions?(%{from: %{id: @group_annonymous_bot_id}} = _message), do: true

  defp no_permissions?(message) do
    %{chat: %{id: chat_id}, from: %{id: user_id}} = message

    case Telegex.get_chat_member(chat_id, user_id) do
      {:ok, %{status: status}} -> status not in ["creator", "administrator"]
      _ -> true
    end
  end
end
