defmodule PolicrMini.Bot.Runner do
  @moduledoc """
  各个定时任务的具体实现模块。
  """

  require Logger

  alias PolicrMini.{VerificationBusiness, ChatBusiness}
  alias PolicrMini.Bot.Helper, as: BotHelper

  @spec fix_expired_wait_status :: :ok
  @doc """
  修正所有过期的等待验证。
  """
  def fix_expired_wait_status do
    # 获取所有处于等待状态的验证
    verifications = VerificationBusiness.find_all_unity_waiting()
    # 计算已经过期的验证
    verifications =
      verifications
      |> Enum.filter(fn v ->
        remaining_seconds = DateTime.diff(DateTime.utc_now(), v.inserted_at)
        remaining_seconds - (v.seconds + 30) > 0
      end)

    # 修正状态
    # TODO: 待优化：在同一个事物中更新所有验证记录
    verifications |> Enum.each(fn v -> v |> VerificationBusiness.update(%{status: :expired}) end)

    len = length(verifications)
    if len > 0, do: Logger.info("Automatically correct #{len} expired verifications")

    :ok
  end

  @spec check_working_status :: :ok
  @doc """
  根据权限自动修正工作状态或退出群组。
  """
  def check_working_status do
    # 获取接管的 chat 列表
    chats = ChatBusiness.find_takeovered()

    cancel_takeover = fn chat ->
      ChatBusiness.takeover_cancelled(chat)

      BotHelper.async(fn ->
        BotHelper.send_message(
          chat.id,
          BotHelper.t("errors.no_permission", %{bot_username: PolicrMini.Bot.username()}),
          parse_mode: nil
        )
      end)

      Logger.info(
        "No permission in the group `#{chat.id}`, the takeover has been automatically cancelled."
      )
    end

    # 检查单个 chat 权限
    check_one = fn chat ->
      case Nadia.get_chat_member(chat.id, PolicrMini.Bot.id()) do
        {:ok, member} ->
          # 检查权限并执行相应修正
          if chat.is_take_over do
            # 如果不是管理员，取消接管
            unless member.status == "administrator", do: cancel_takeover.(chat)
            # 如果没有限制用户权限，取消接管
            if member.can_restrict_members == false, do: cancel_takeover.(chat)
          end

          # 如果没有发消息权限，直接退出
          if member.can_send_messages == false do
            Nadia.leave_chat(chat.id)
            Logger.info("Unable to send message in group `#{chat.id}`, has left automatically.")
          end

        e ->
          Logger.error("An error occurred while checking bot permissions. Details: #{inspect(e)}")
      end

      # 休眠半秒检查下一个
      :timer.sleep(500)
    end

    chats |> Enum.each(fn chat -> check_one.(chat) end)

    :ok
  end
end
