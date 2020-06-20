defmodule PolicrMini.Bot.Runner do
  @moduledoc """
  各定时任务实现模块。
  """

  require Logger

  alias PolicrMini.VerificationBusiness

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
    verifications |> Enum.each(fn v -> v |> VerificationBusiness.update(%{status: :expired}) end)

    len = length(verifications)
    if len > 0, do: Logger.info("Automatically correct #{len} expired verifications")

    :ok
  end
end
