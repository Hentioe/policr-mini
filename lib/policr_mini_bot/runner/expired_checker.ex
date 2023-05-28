defmodule PolicrMiniBot.Runner.ExpiredChecker do
  @moduledoc false

  alias PolicrMini.Chats
  alias PolicrMini.Chats.Verification

  require Logger
  require PolicrMiniBot.Helper

  import PolicrMiniBot.Helper

  @spec run :: :ok

  @doc """
  修正所有过期的等待验证。
  """
  def run do
    # 获取所有处于等待状态的验证
    vs = Chats.find_all_pending_verifications()
    # 计算已经过期的验证列表
    vs = Enum.filter(vs, &expired?/1)

    # 修正状态
    # TODO: 待优化：在同一个事物中更新所有验证记录
    Enum.each(vs, fn v ->
      # 自增统计数据（其它）
      async_run(fn ->
        Chats.increment_statistic(v.chat_id, v.target_user_language_code, :other)
      end)

      # 更新为过期状态
      Chats.update_verification(v, %{status: :expired})
      # 处理验证用户
      user_processing(v)
    end)

    auto_corrected_logging(vs)
  end

  @spec user_processing(Verification.t()) :: :ok
  # 来源为 `:join_request` 的验证，拒绝加入请求
  defp user_processing(%{source: :join_request} = v) do
    async_run(fn -> Telegex.decline_chat_join_request(v.chat_id, v.target_user_id) end)

    :ok
  end

  # 来源为 `:joined` 的验证，忽略处理（因为权限已被限制）
  defp user_processing(%{source: :joined} = _v) do
    :ok
  end

  @spec auto_corrected_logging([Verification.t()]) :: :ok | :ignore
  defp auto_corrected_logging([v]) do
    Logger.warning(
      "Auto-corrected a verification: #{inspect(id: v.id, user_id: v.target_user_id)}",
      chat_id: v.chat_id
    )

    :ok
  end

  defp auto_corrected_logging([]) do
    :ignore
  end

  defp auto_corrected_logging(vs) do
    Logger.warning("Auto-corrected #{length(vs)} verifications")

    :ok
  end

  defp expired?(v) do
    remaining_seconds = DateTime.diff(DateTime.utc_now(), v.inserted_at)
    remaining_seconds - (v.seconds + 30) > 0
  end
end
