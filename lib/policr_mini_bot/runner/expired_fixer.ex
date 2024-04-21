defmodule PolicrMiniBot.Runner.ExpiredFixer do
  @moduledoc false

  alias PolicrMini.{Chats, Stats}
  alias PolicrMini.Chats.Verification

  require Logger
  require PolicrMiniBot.Helper

  import PolicrMiniBot.Helper

  @spec run :: :done

  @doc """
  修正所有过期的等待验证。
  """
  def run do
    # 获取所有处于等待状态的验证
    all_expired = all_expired()

    # 修正所有状态。
    rs = Enum.map(all_expired, &expired_processing/1)
    failed_count = Enum.count(rs, &(&1 == :error))
    succeeded_count = Enum.count(rs, &(&1 == :ok))

    # 修正 x 个过期验证失败
    if failed_count > 0 do
      Logger.error("Correct #{failed_count} expired verification(s) failed")
    end

    if succeeded_count > 0 do
      Logger.warning("Corrected #{succeeded_count} expired verification(s)")
    end

    :done
  end

  defp all_expired do
    vs = Chats.find_all_pending_verifications()

    Enum.filter(vs, &expired?/1)
  end

  # 处理已过期
  def expired_processing(v) when is_struct(v, Verification) do
    # 开始修正过期验证
    Logger.debug("Start correcting expired verification: #{inspect(user_id: v.target_user_id)}",
      chat_id: v.chat_id
    )

    case Chats.update_verification(v, %{status: :expired}) do
      {:ok, v} ->
        # 写入验证数据点（其它）
        Stats.write(v)

        # 处理用户
        handle_user(v)

        :ok

      {:error, reason} ->
        # 更新过期验证失败
        Logger.error("Update expired verification failed: #{inspect(reason: reason)}")

        :error
    end
  end

  @spec handle_user(Verification.t()) :: :ok
  # 来源为 `:join_request` 的验证，拒绝加入请求
  defp handle_user(%{source: :join_request} = v) do
    async_run(fn -> Telegex.decline_chat_join_request(v.chat_id, v.target_user_id) end)

    :ok
  end

  # 来源为 `:joined` 的验证，忽略处理（因为权限已被限制）
  defp handle_user(%{source: :joined} = _v) do
    :ok
  end

  defp expired?(v) do
    remaining_seconds = DateTime.diff(DateTime.utc_now(), v.inserted_at)
    remaining_seconds - (v.seconds + 30) > 0
  end
end
