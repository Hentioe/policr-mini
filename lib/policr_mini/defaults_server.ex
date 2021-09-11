defmodule PolicrMini.DefaultsServer do
  @moduledoc """
  获取并维护全局默认值的服务。
  """

  use GenServer

  alias PolicrMini.{Logger, Chats}

  def start_link(_) do
    {:ok, scheme} = Chats.fetch_default_scheme()

    GenServer.start_link(__MODULE__, %{scheme: scheme}, name: __MODULE__)
  end

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

  def handle_call({:get_scheme_value, field}, _from, state) do
    value =
      state
      |> Map.get(:scheme)
      |> Map.get(field)

    {:reply, value, state}
  end

  def handle_call({:get_scheme}, _from, state) do
    {:reply, Map.get(state, :scheme), state}
  end

  def handle_cast({:update_scheme, params}, state) do
    scheme = Map.get(state, :scheme)

    case Chats.update_scheme(scheme, params) do
      {:ok, scheme} ->
        {:noreply, Map.put(state, :scheme, scheme)}

      _ ->
        Logger.unitized_error("Default scheme update", params: params)

        {:noreply, state}
    end
  end
end
