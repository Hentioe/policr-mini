defmodule PolicrMini.DefaultProvider do
  @moduledoc false

  use GenServer

  alias Ecto.Changeset
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

  @spec scheme :: PolicrMini.Chats.Scheme.t()
  def scheme do
    GenServer.call(__MODULE__, :get_scheme)
  end

  @spec scheme_update(PolicrMini.Schema.params()) :: :ok
  def scheme_update(params) do
    GenServer.cast(__MODULE__, {:update_scheme, params})
  end

  @spec scheme_update_sync(PolicrMini.Schema.params()) ::
          {:ok, Scheme.t()} | {:error, Changeset.t()}
  def scheme_update_sync(params) do
    GenServer.call(__MODULE__, {:update_scheme, params})
  end

  @impl true
  def handle_call(:get_scheme, _from, state) do
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
