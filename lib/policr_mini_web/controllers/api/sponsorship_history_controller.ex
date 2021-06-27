defmodule PolicrMiniWeb.API.SponsorshipHistoryController do
  @moduledoc """
  赞助历史的前台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.SponsorshipHistoryBusiness

  action_fallback(PolicrMiniWeb.API.FallbackController)

  @hints %{
           "@1" => {"给作者买单一份外卖", 25},
           "@2" => {"为服务器续费一个月", 55},
           "@3" => {"承担下个月的运营成本", 99},
           "@4" => {"项目功能的进一步完善", 150},
           "@5" => {"此星期内作者能为项目付出更多的时间", 199},
           "@6" => {"让作者帮忙解决一些小的技术问题", 299},
           "@7" => {"让作者帮忙解决一些技术难题", 599},
           "@8" => {"让作者承接自己的项目", 999},
           "@9" => {"宣传或展示企业、产品自身", 1999}
         }
         |> Enum.map(fn {ref, {expected_to, amount}} ->
           %{ref: ref, expected_to: expected_to, amount: amount}
         end)

  @order_by [desc: :reached_at]
  def index(conn, _params) do
    sponsorship_histories =
      SponsorshipHistoryBusiness.find_list(
        has_reached: true,
        preload: [:sponsor],
        order_by: @order_by
      )

    render(conn, "index.json", %{
      sponsorship_histories: sponsorship_histories,
      hints: @hints
    })
  end

  def add(conn, %{"sponsor" => sponsor} = params) when sponsor != nil do
    with {:ok, sponsorship_history} <-
           SponsorshipHistoryBusiness.create_with_sponsor(params) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end

  def add(conn, params) do
    with {:ok, sponsorship_history} <-
           SponsorshipHistoryBusiness.create(params) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end
end
