defmodule PolicrMiniBot.Disposable do
  @moduledoc false

  # TODO：增加超时时间支持，并定时扫描和清理已超时的保证。

  use GenServer

  @type status :: :processing | :done

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @type key :: integer | binary

  @doc """
  添加一个一次性处理保证。

  如果指定的 key 没有已存在的状态，则设置为 `:processing` 状态并返回 `:ok`。否则将返回 `{:repeat, status}`，其中的 status 表示已存在的状态。
  """
  @spec processing(key) :: :ok | {:repeat, status}
  def processing(key) do
    case GenServer.call(__MODULE__, {:get_and_put_new_status, key, :processing}) do
      nil -> :ok
      status -> {:repeat, status}
    end
  end

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
end
