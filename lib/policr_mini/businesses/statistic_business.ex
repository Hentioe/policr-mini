defmodule PolicrMini.StatisticBusiness do
  @moduledoc """
  用户业务功能的实现。
  """

  use PolicrMini, business: PolicrMini.Schemas.Statistic

  import Ecto.Query, only: [from: 2]

  @type written_returns :: {:ok, Statistic.t()} | {:error, Ecto.Changeset.t()}
  @type status :: :passed | :timeout | :wronged | :other

  @spec create(map) :: written_returns
  def create(params) do
    %Statistic{} |> Statistic.changeset(params) |> Repo.insert()
  end

  @spec update(Statistic.t(), map) :: written_returns
  def update(statistic, params) do
    statistic |> Statistic.changeset(params) |> Repo.update()
  end

  @day_seconds 3600 * 24
  @zero_oclock ~T[00:00:00]

  @spec find_today(integer, status) :: Statistic.t() | nil
  def find_today(chat_id, status) do
    # 创建今天的开始时间和结束时间。
    {begin_at, end_at} = today_begin_and_end_datetimes()

    from(
      s in Statistic,
      where:
        s.chat_id == ^chat_id and
          s.verification_status == ^status and
          s.begin_at >= ^begin_at and
          s.end_at <= ^end_at
    )
    |> Repo.one()
  end

  @doc """
  自增一个当天的统计。
  """
  @spec increment_one(integer, String.t(), status) :: {:ok, Statistic.t()} | {:error, any}
  def increment_one(chat_id, language_code, status) do
    language_code = language_code || "unknown"

    fetch_stat = fn ->
      case find_today(chat_id, status) do
        nil ->
          {begin_at, end_at} = today_begin_and_end_datetimes()

          create(%{
            chat_id: chat_id,
            verifications_count: 0,
            languages_top: %{language_code => 0},
            begin_at: begin_at,
            end_at: end_at,
            verification_status: status
          })

        stat ->
          {:ok, stat}
      end
    end

    trans_fun = fn ->
      trans_r = increment_trans(fetch_stat, language_code)

      case trans_r do
        {:ok, r} -> r
        e -> e
      end
    end

    Repo.transaction(trans_fun)
  end

  defp increment_trans(fetch_stat, language_code) do
    case fetch_stat.() do
      {:ok, stat} ->
        verifications_count = stat.verifications_count + 1

        languages_top =
          if count = stat.languages_top[language_code] do
            Map.put(stat.languages_top, language_code, count + 1)
          else
            Map.put(stat.languages_top, language_code, 1)
          end

        update(stat, %{verifications_count: verifications_count, languages_top: languages_top})

      e ->
        e
    end
  end

  defp today_begin_and_end_datetimes do
    begin_at = DateTime.new!(Date.utc_today(), @zero_oclock, "Etc/UTC")
    end_at = DateTime.add(begin_at, @day_seconds - 1, :second)

    {begin_at, end_at}
  end
end
