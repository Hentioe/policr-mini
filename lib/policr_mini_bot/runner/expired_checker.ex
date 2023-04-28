defmodule PolicrMiniBot.Runner.ExpiredChecker do
  @moduledoc false

  alias PolicrMini.Logger
  alias PolicrMini.{VerificationBusiness, StatisticBusiness}

  require PolicrMiniBot.Helper
  import PolicrMiniBot.Helper

  @spec run :: :ok

  @doc """
  修正所有过期的等待验证。
  """
  def run do
    # 获取所有处于等待状态的验证
    verifications = VerificationBusiness.find_all_waiting_verifications()
    # 计算已经过期的验证
    verifications =
      verifications
      |> Enum.filter(fn v ->
        remaining_seconds = DateTime.diff(DateTime.utc_now(), v.inserted_at)
        remaining_seconds - (v.seconds + 30) > 0
      end)

    # 修正状态
    # TODO: 待优化：在同一个事物中更新所有验证记录
    verifications
    |> Enum.each(fn verification ->
      # 自增统计数据（其它）。
      async do
        StatisticBusiness.increment_one(
          verification.chat_id,
          verification.target_user_language_code,
          :other
        )
      end

      verification |> VerificationBusiness.update(%{status: :expired})
    end)

    len = length(verifications)
    if len > 0, do: Logger.info("Automatically correct #{len} expired verifications")

    :ok
  end
end
