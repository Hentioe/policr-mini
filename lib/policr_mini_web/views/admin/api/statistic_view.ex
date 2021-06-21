defmodule PolicrMiniWeb.Admin.API.StatisticView do
  @moduledoc """
  渲染后台统计数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("statistic.json", %{statistic: nil}) do
    %{statistic: nil}
  end

  def render("statistic.json", %{statistic: statistic}) do
    statistic |> Map.drop([:__meta__, :chat]) |> Map.from_struct()
  end

  def render("day.json", %{
        day: %{
          passed_statistic: passed_statistic,
          timeout_statistic: timeout_statistic,
          wronged_statistic: wronged_statistic
        }
      }) do
    passed_statistic = render_one(passed_statistic, __MODULE__, "statistic.json")
    timeout_statistic = render_one(timeout_statistic, __MODULE__, "statistic.json")
    wronged_statistic = render_one(wronged_statistic, __MODULE__, "statistic.json")

    %{
      passed_statistic: passed_statistic,
      timeout_statistic: timeout_statistic,
      wronged_statistic: wronged_statistic
    }
  end

  def render("recently.json", %{yesterday: yesterday, today: today}) do
    yesterday = render_one(yesterday, __MODULE__, "day.json", as: :day)
    today = render_one(today, __MODULE__, "day.json", as: :day)

    %{
      yesterday: yesterday,
      today: today
    }
  end
end
