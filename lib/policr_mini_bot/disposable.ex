defmodule PolicrMiniBot.Disposable do
  @moduledoc """
  一次性处理的保证服务。

  此模块可以为并发环境下只允许调用一次的任务强制保证一次性状态。当给同一个的 key
  二次添加保证时将返回处理中或完成处理两个状态，这样便可在任务执行前就知道任务是否执行过。状态在完成处理或超时后自动清理。
  """

  use GenServer

  @type unix_datetime :: integer
  @type status_type :: :processing | :done
  @type status_value :: {:processing, unix_datetime} | :done
  @type second :: integer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_clean()
    {:ok, state}
  end

  @type key :: integer | binary

  @doc """
  添加一个一次性处理保证。

  如果指定的 key 不存在，则设置为 `{:processing, expired_unix}` 状态并返回 `:ok`。其中
  `expired_unix` 变量表示以计算当前时间和超时时间得出的过期时间戳，它用于清理任务。否则将返回
  `{:repeat, status}`，其中的 `status` 变量表示已存在的状态。

  *注意*：设置了超时时间并不表示会按时清理，因为清理任务是以固定时间轮询执行的。
  """
  @spec processing(key, second) :: :ok | {:repeat, status_type}
  def processing(key, timeout \\ 5) do
    value = {:processing, now_unix() + timeout}

    case GenServer.call(__MODULE__, {:get_and_put_new_status, key, value}) do
      nil -> :ok
      {:processing, _expired_unix} -> {:repeat, :processing}
      :done -> {:repeat, :done}
    end
  end

  @doc """
  完成一次性处理的保证状态。

  直接将指定 key 的状态设置为 `:done`，此状态最终会被清理任务删除，和 `PolicrMiniBot.Disposable.processing/2`
  函数的 `timeout` 参数类似，清理并不是即时的。
  """
  @spec done(key) :: :ok
  def done(key) do
    GenServer.cast(__MODULE__, {:set_status, key, :done})
  end

  @impl true
  def handle_call({:get_status, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  # 获取并更新不存在的状态（如果状态已存在则不更新）。
  @impl true
  def handle_call({:get_and_put_new_status, key, new_status}, _from, state) do
    status = Map.get(state, key)

    state =
      if status == nil do
        Map.put(state, key, new_status)
      else
        state
      end

    {:reply, status, state}
  end

  @impl true
  def handle_cast({:set_status, key, status}, state) do
    {:noreply, Map.put(state, key, status)}
  end

  # 执行清理任务
  @impl true
  def handle_info(:clean, state) do
    now_unix = now_unix()
    state = state |> Enum.filter(&retain?(&1, now_unix)) |> Enum.into(%{})

    schedule_clean()
    {:noreply, state}
  end

  @spec now_unix() :: unix_datetime
  defp now_unix(), do: DateTime.to_unix(DateTime.utc_now())

  @spec retain?({key, status_value}, unix_datetime) :: boolean
  defp retain?({_key, :done}, _now_unix), do: false

  defp retain?({_key, {:processing, expired_unix}}, now_unix) when is_integer(expired_unix),
    do: now_unix < expired_unix

  # 每一分钟清理一次（此时间可在启动 GenServer 时通过参数传递）
  @clean_sleep_time 1000 * 60

  @spec schedule_clean() :: :ok
  defp schedule_clean() do
    Process.send_after(__MODULE__, :clean, @clean_sleep_time)

    :ok
  end
end
