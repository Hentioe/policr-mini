defmodule PolicrMiniBot.Disposable do
  @moduledoc false

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
  @spec processing(key) :: :ok | {:repeat, status}
  def processing(key) do
    case GenServer.call(__MODULE__, {:get_status, key}) do
      nil -> GenServer.cast(__MODULE__, {:set_status, key, :processing})
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

  @impl true
  def handle_cast({:set_status, key, status}, state) do
    {:noreply, Map.put(state, key, status)}
  end
end
