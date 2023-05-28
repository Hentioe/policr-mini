defmodule PolicrMiniBot.RespSyncCmdPlug do
  @moduledoc """
  `/sync` 命令的响应模块。

  此命令存在速度限制，15 秒内只能调用一次。
  """

  use PolicrMiniBot, plug: [commander: :sync]

  alias PolicrMini.{Instances, Chats}
  alias PolicrMini.Instances.Chat
  alias PolicrMiniBot.{SpeedLimiter, Worker}
  alias PolicrMiniBot.Helper.Syncing

  require Logger

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
        send_text(
          chat_id,
          commands_text("同步过于频繁，请在 %{sec_count} 秒后重试。",
            sec_count: waiting_sec
          ),
          logging: true
        )

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
             {:ok, _scheme} <- Chats.find_or_init_scheme(chat_id),
             {:ok, member} <- Telegex.get_chat_member(chat_id, PolicrMiniBot.id()) do
          # 检查是否具备接管权限，如果具备则自动接管验证
          has_takeover_permissions = check_takeover_permissions(member) == :ok

          is_taken_over =
            if has_takeover_permissions do
              Instances.update_chat(chat, %{is_take_over: true})

              true
            else
              Instances.cancel_chat_takeover(chat)

              false
            end

          ttitle = commands_text("同步成功")
          tupdate_chat = "✔️ " <> commands_text("已更新群组资料。")
          tupdate_admins = "✔️ " <> commands_text("已更新管理员权限。")

          ttakeover =
            if has_takeover_permissions do
              text =
                if is_taken_over do
                  commands_text("新成员验证已处于接管状态。")
                else
                  commands_text("因为本机器人具备权限，已接管新成员验证。")
                end

              "✔️ " <> text
            else
              text =
                if is_taken_over do
                  commands_text("由于本机器人缺失必要管理权限，已取消对新成员验证的接管。")
                else
                  commands_text("因为本机器人缺失必要管理权限，所以无法接管新成员验证。")
                end

              "⚠️ " <> text
            end

          text = """
          *#{ttitle}*

          #{tupdate_chat}
          #{tupdate_admins}
          #{ttakeover}
          """

          async_run(fn -> send_text(chat_id, text, parse_mode: "MarkdownV2", logging: true) end)
        else
          {:error, reason} ->
            Logger.error("Sync of permissions failed: #{inspect(reason: reason)}")

            send_text(chat_id, commands_text("出现了一些问题，同步失败。请联系开发者。"), logging: true)
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
