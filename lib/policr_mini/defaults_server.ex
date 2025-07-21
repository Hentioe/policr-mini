defmodule PolicrMini.DefaultsServer do
  @moduledoc """
  获取并维护全局默认值的服务。
  """

  use GenServer

  alias PolicrMini.Chats
  alias PolicrMini.Chats.Scheme

  require Logger

  def start_link(_) do
    {:ok, scheme} = Chats.default_scheme()

    GenServer.start_link(__MODULE__, %{scheme: scheme}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @spec get_scheme_value(atom) :: any
  def get_scheme_value(field) do
    GenServer.call(__MODULE__, {:get_scheme_value, field})
  end

  @spec get_scheme :: PolicrMini.Chats.Scheme.t()
  def get_scheme do
    GenServer.call(__MODULE__, {:get_scheme})
  end

  @spec update_scheme(PolicrMini.Schema.params()) :: :ok
  def update_scheme(params) do
    GenServer.cast(__MODULE__, {:update_scheme, params})
  end

  @spec update_scheme_sync(PolicrMini.Schema.params()) :: {:ok, Scheme.t()} | {:error, any}
  def update_scheme_sync(params) do
    GenServer.call(__MODULE__, {:update_scheme, params})
  end

  def handle_call({:get_scheme_value, field}, _from, state) do
    value =
      state
      |> Map.get(:scheme)
      |> Map.get(field)

    {:reply, value, state}
  end

  @impl true
  def handle_call({:get_scheme}, _from, state) do
    {:reply, Map.get(state, :scheme), state}
  end

  @impl true
  def handle_call({:update_scheme, params}, _from, state) do
    scheme = Map.get(state, :scheme)

    case Chats.update_scheme(scheme, params) do
      {:ok, scheme} = okr ->
        {:reply, okr, Map.put(state, :scheme, scheme)}

      err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_cast({:update_scheme, params}, state) do
    scheme = Map.get(state, :scheme)

    case Chats.update_scheme(scheme, params) do
      {:ok, scheme} ->
        {:noreply, Map.put(state, :scheme, scheme)}

      {:error, reason} ->
        Logger.error("Update default scheme failed: #{inspect(params: params, reason: reason)}")

        {:noreply, state}
    end
  end
end
