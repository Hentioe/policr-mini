defmodule PolicrMiniBot.Runner.WorkingChecker do
  @moduledoc """
  工作状态检查任务。

  此模块会定期检查被接管群组中的机器人权限、以及是否已离开等状态。在不满足最低权限要求时给予提示并自动取消接管，或对已离开的群组直接取消接管。
  当发现普通群（非超级群）将直接取消接管，并删除所有权限记录。当发现频道时将直接取消接管。
  """

  alias PolicrMini.{Logger, Instances, Instances.Chat, ChatBusiness, PermissionBusiness}
  alias PolicrMiniBot.Helper, as: BotHelper

  @spec run :: :ok

  @doc """
  根据权限自动修正工作状态或退出群组。
  """
  def run do
    Logger.debug("Working status check starts")

    takeovred_chats = ChatBusiness.find_takeovered()

    _ =
      takeovred_chats
      |> Stream.each(&check_chat/1)
      |> Enum.to_list()

    Logger.debug(
      "Working status check ended, details: #{inspect(count: length(takeovred_chats))}"
    )

    :ok
  end

  # 普通群，提示并退出。
  defp check_chat(%{id: chat_id, is_take_over: true, type: "group"}) do
    BotHelper.send_message(chat_id, BotHelper.t("errors.no_super_group"))

    Telegex.leave_chat(chat_id)
  end

  # 频道，直接退出。
  defp check_chat(%{id: chat_id, is_take_over: true, type: "channel"}),
    do: Telegex.leave_chat(chat_id)

  # 检查必要的权限，并在不满足时进行相对应的处理。
  defp check_chat(%{is_take_over: true} = chat) do
    case Telegex.get_chat_member(chat.id, PolicrMiniBot.id()) do
      {:ok, member} ->
        # 检查权限并执行相应修正。

        # 如果不是管理员，取消接管
        unless member.status == "administrator",
          do: cancel_takeover(chat, reason: :no_admin)

        # 如果没有限制用户权限，取消接管
        if member.can_restrict_members == false,
          do: cancel_takeover(chat, reason: :missing_permissions)

        # 如果没有删除消息权限，取消接管
        if member.can_delete_messages == false,
          do: cancel_takeover(chat, reason: :missing_permissions)

        # 如果没有发消息权限，直接退出
        if member.can_send_messages == false do
          Telegex.leave_chat(chat.id)

          msg =
            "Missing permission to send messages, has left automatically, details: #{inspect(chat_id: chat.id)}"

          Logger.warn(msg)
        end

      {:error, %Telegex.Model.RequestError{reason: :timeout}} ->
        # 处理超时，自动重试。
        msg =
          "Requesting own permission timed out, waiting for retry, details: #{inspect(chat_id: chat.id)}"

        Logger.warn(msg)

        :timer.sleep(15)
        check_chat(chat)

      {:error, error} ->
        # 检查时发生错误，进一步处理错误。
        handle_check_error(error, chat)
    end
  end

  @error_description_bot_was_kicked "Forbidden: bot was kicked from the supergroup chat"
  @error_description_bot_is_not_member [
    # 超级群
    "Forbidden: bot is not a member of the supergroup chat",
    # 普通群
    "Forbidden: bot is not a member of the group chat"
  ]
  @error_description_chat_not_found "Bad Request: chat not found"
  @error_description_was_upgraded_supergroup "Bad Request: group chat was upgraded to a supergroup chat"

  # 机器人被封禁，取消接管。
  defp handle_check_error(%Telegex.Model.Error{description: description}, chat)
       when description == @error_description_bot_was_kicked,
       do: cancel_takeover(chat, reason: :kicked, send_notification: false)

  # 机器人已不在群中，取消接管。
  defp handle_check_error(%Telegex.Model.Error{description: description}, chat)
       when description in @error_description_bot_is_not_member,
       do: cancel_takeover(chat, reason: :left, send_notification: false)

  # 已被升级为超级群，取消接管。
  # 一些未经证实的猜测：
  # 此错误提示表示旧群 ID 仍然被 TG 识别，但是 ID 的作用已被废弃。理论上这类群组需要清理，否则会出现资料重复的群组。
  defp handle_check_error(%Telegex.Model.Error{description: description}, chat)
       when description == @error_description_was_upgraded_supergroup,
       do: cancel_takeover(chat, reason: :upgraded, send_notification: false)

  # 群组已不存在。取消接管，并删除与之相关的用户权限。
  defp handle_check_error(%Telegex.Model.Error{description: description}, chat)
       when description == @error_description_chat_not_found do
    cancel_takeover(chat, reason: :not_found, send_notification: false)

    PermissionBusiness.delete_all(chat.id)
  end

  # 未知错误。
  defp handle_check_error(error, chat)
       when is_struct(error, Telegex.Model.Error) or is_struct(error, Telegex.Model.RequestError),
       do: Logger.unitized_error("Bot permission check", chat_id: chat.id, error: error)

  @type cancel_takeover_opts :: [reason: atom, send_notification: boolean]

  # 取消接管
  @spec cancel_takeover(Chat.t(), cancel_takeover_opts) :: :ok
  defp cancel_takeover(%Chat{id: chat_id} = chat, opts)
       when is_integer(chat_id) and is_list(opts) do
    Instances.cancel_chat_takeover(chat)

    if Keyword.get(opts, :send_notification, true),
      do:
        BotHelper.async_run(fn ->
          BotHelper.send_message(
            chat.id,
            BotHelper.t("errors.no_permission", %{bot_username: PolicrMiniBot.username()}),
            parse_mode: nil
          )
        end)

    reason = Keyword.get(opts, :reason, :none)

    msg =
      "Takeover is automatically cancelled, details: #{inspect(chat_id: chat_id, reason: reason)}"

    Logger.warn(msg)

    :ok
  end
end
