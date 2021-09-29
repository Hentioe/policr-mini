defmodule PolicrMiniWeb.API.SponsorshipHistoryController do
  @moduledoc """
  赞助历史的前台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.Instances
  alias PolicrMiniBot.SpeedLimiter

  action_fallback(PolicrMiniWeb.API.FallbackController)

  @hints_map %{
    "@1" => {"给作者买单一份外卖", 25},
    "@2" => {"为服务器续费一个月", 55},
    "@3" => {"承担下个月的所有运营开销", 99},
    "@4" => {"项目功能的进一步完善", 150},
    "@5" => {"此星期内作者能为项目付出更多的时间", 199},
    "@6" => {"让作者协助解决一些小的技术问题", 299},
    "@7" => {"让作者协助解决一些技术难题", 599},
    "@9" => {"宣传或展示企业、产品自身", 999}
  }
  @hints Enum.map(@hints_map, fn {ref, {expected_to, amount}} ->
           %{ref: ref, expected_to: expected_to, amount: amount}
         end)

  @order_by [desc: :reached_at]

  def index(conn, _params) do
    sponsorship_histories =
      Instances.find_sponsorship_histrories(
        has_reached: true,
        preload: [:sponsor],
        order_by: @order_by
      )

    render(conn, "index.json", %{
      sponsorship_histories: sponsorship_histories,
      hints: @hints
    })
  end

  def add(conn, %{"uuid" => uuid} = params) when uuid != nil do
    with {:ok, chat_id} <- check_token(params),
         {:ok, sponsor} <- find_sponsor_by_uuid(uuid),
         {:ok, params} <-
           preprocessing_params(Map.put(params, "sponsor_id", sponsor.id), chat_id),
         {:ok, sponsorship_history} <- Instances.create_sponsorship_histrory(params) do
      :ok = chat_id |> build_speed_limit_key() |> SpeedLimiter.put(10)

      render(conn, "added.json", %{sponsorship_history: sponsorship_history, uuid: uuid})
    end
  end

  def add(conn, params) do
    with {:ok, chat_id} <- check_token(params),
         {:ok, params} <- preprocessing_params(params, chat_id),
         {:ok, sponsorship_history} <-
           Instances.create_sponsorship_histrory_with_sponsor(params) do
      :ok = chat_id |> build_speed_limit_key() |> SpeedLimiter.put(30)

      render(conn, "added.json", %{
        sponsorship_history: sponsorship_history,
        uuid: sponsorship_history.sponsor.uuid
      })
    end
  end

  defp find_sponsor_by_uuid(uuid) do
    case Instances.find_sponsor(uuid: uuid) do
      nil -> {:error, %{description: "没有找到此 UUID 关联的赞助者"}}
      sponsor -> {:ok, sponsor}
    end
  end

  defp preprocessing_params(%{"expected_to" => ref} = params, chat_id) do
    if hint = @hints_map[ref] do
      expected_to = elem(hint, 0)

      params =
        params
        |> Map.put("expected_to", expected_to)
        |> Map.put("has_reached", false)
        |> Map.put("creator", chat_id)

      {:ok, params}
    else
      {:error, %{description: "预期用途的引用值 `#{ref}` 是无效的"}}
    end
  end

  @spec check_token(map) :: {:ok, integer} | {:error, map}
  defp check_token(%{"token" => token}) do
    if chat_id = Cachex.get!(:sponsorship, token) do
      sec = chat_id |> build_speed_limit_key() |> SpeedLimiter.get()

      if sec > 0 do
        {:error, %{description: "您太快了，请在 #{sec} 秒后再试"}}
      else
        {:ok, chat_id}
      end
    else
      {:error, %{description: "赞助口令无效或已失效"}}
    end
  end

  defp check_token(_params) do
    {:error, %{description: "缺少赞助口令参数"}}
  end

  defp build_speed_limit_key(chat_id), do: "sponsorship-#{chat_id}"
end
