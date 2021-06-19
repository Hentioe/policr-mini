defmodule PolicrMiniWeb.Admin.API.StatisticController do
  @moduledoc """
  和统计相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.StatisticBusiness

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.API.FallbackController

  def find_today(conn, params) do
    chat_id = params["chat_id"]

    with {:ok, _} <- check_permissions(conn, chat_id, [:readable]) do
      passed_statistic = StatisticBusiness.find_today(chat_id, :passed)
      timeout_statistic = StatisticBusiness.find_today(chat_id, :timeout)
      wronged_statistic = StatisticBusiness.find_today(chat_id, :wronged)

      render(conn, "today.json", %{
        passed_statistic: passed_statistic,
        timeout_statistic: timeout_statistic,
        wronged_statistic: wronged_statistic
      })
    end
  end
end
