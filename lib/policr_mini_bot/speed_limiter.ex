defmodule PolicrMiniBot.SpeedLimiter do
  @moduledoc """
  速度限制器。

  此模块记录指定 `key` 的插入（或更新）时间以及过期时间，并轮询删除过期数据。若根据 `key` 能读取到数据，表示未过期，即在限速的范围内。
  注意：过期时间不得小于 1 秒，因为此时间为一个轮询周期。
  """

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  插入一个限制器记录。

  ## 参数
  - `key`: 访问该限制记录的钥匙。若已存在，将更新至最新的时间。
  - `expired`: 过期时间。单位秒，不得小于 1。
  """
  def put(key, expired) do
    GenServer.cast(__MODULE__, {:put, key, expired})
  end

  @doc """
  读取指定限制器记录的剩余时间，单位为秒。

  若已不在限速范围内，将返回 `0`。注意，任何已不存在的限速记录都返回 `0`。
  """
  def get(key) do
    if value = GenServer.call(__MODULE__, {:get, key}) do
      {dt, expired} = value

      dt + expired - now_unix()
    else
      0
    end
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:put, key, expired}, state) do
    schedule_expire_check()

    {:noreply, Map.put(state, key, {now_unix(), expired})}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  # 执行检查任务。
  @impl true
  def handle_info(:expire_check, state) do
    now_unix = now_unix()
    state = state |> Enum.filter(&not_expired?(&1, now_unix)) |> Enum.into(%{})

    schedule_expire_check()

    {:noreply, state}
  end

  defp not_expired?({_key, {dt, expired}}, now_unix) do
    dt + expired > now_unix
  end

  defp now_unix, do: DateTime.to_unix(DateTime.utc_now())

  @expire_check_time 500

  @spec schedule_expire_check() :: :ok
  defp schedule_expire_check() do
    Process.send_after(__MODULE__, :expire_check, @expire_check_time)

    :ok
  end
end
