defmodule PolicrMiniWeb.Admin.API.StatisticController do
  @moduledoc """
  和统计相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.Chats

  import PolicrMiniWeb.Helper

  action_fallback PolicrMiniWeb.API.FallbackController

  def find_recently(conn, params) do
    chat_id = params["chat_id"]

    with {:ok, _} <- check_permissions(conn, chat_id, [:readable]) do
      today = %{
        passed_statistic: Chats.find_today_stat(chat_id, :passed),
        timeout_statistic: Chats.find_today_stat(chat_id, :timeout),
        wronged_statistic: Chats.find_today_stat(chat_id, :wronged)
      }

      yesterday = %{
        passed_statistic: Chats.find_yesterday_stat(chat_id, :passed),
        timeout_statistic: Chats.find_yesterday_stat(chat_id, :timeout),
        wronged_statistic: Chats.find_yesterday_stat(chat_id, :wronged)
      }

      render(conn, "recently.json", %{
        yesterday: yesterday,
        today: today
      })
    end
  end
end
