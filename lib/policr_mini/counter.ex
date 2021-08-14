defmodule PolicrMini.Counter do
  @moduledoc """
  计数器缓存实现。
  """

  use GenServer

  alias PolicrMini.VerificationBusiness

  defmodule State do
    @moduledoc false

    defstruct [:verification_total, :verification_passed_total, :verification_timeout_total]

    @type t :: %__MODULE__{
            verification_total: integer,
            verification_passed_total: integer,
            verification_timeout_total: integer
          }

    use PolicrMini.Mnesia

    def init(node_list) do
      Mnesia.create_table(__MODULE__,
        attributes: [:key, :value],
        ram_copies: node_list
      )
    end

    @spec update(atom, integer) :: :ok
    def update(key, value) do
      Mnesia.dirty_write({__MODULE__, key, value})
    end

    @spec update_counter(atom, integer) :: integer
    def update_counter(key, value) do
      Mnesia.dirty_update_counter(__MODULE__, key, value)
    end

    def get(key) do
      case Mnesia.dirty_read(__MODULE__, key) do
        [{__MODULE__, _key, value}] -> value
        [] -> 0
      end
    end
  end

  def start_link(_opts) do
    state = %State{
      verification_total: VerificationBusiness.find_total(),
      verification_passed_total: VerificationBusiness.find_total(status: :passed),
      verification_timeout_total: VerificationBusiness.find_total(status: :timeout)
    }

    GenServer.start_link(__MODULE__, %{init: state}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    %{
      verification_total: verification_total,
      verification_passed_total: verification_passed_total,
      verification_timeout_total: verification_timeout_total
    } = state[:init]

    :ok = State.update(:verification_total, verification_total)
    :ok = State.update(:verification_passed_total, verification_passed_total)
    :ok = State.update(:verification_timeout_total, verification_timeout_total)

    {:ok, state}
  end

  @type key :: :verification_total | :verification_passed_total | :verification_timeout_total
  @spec get(key) :: integer
  def get(key) do
    GenServer.call(__MODULE__, {:get_value, key})
  end

  @spec increment(key) :: :ok
  def increment(key) do
    GenServer.cast(__MODULE__, {:increment, key})
  end

  @impl true
  def handle_call({:get_value, key}, _from, state) do
    value = PolicrMini.Counter.State.get(key)

    {:reply, value, state}
  end

  @impl true
  def handle_cast({:increment, key}, state) do
    PolicrMini.Counter.State.update_counter(key, 1)

    {:noreply, state}
  end
end
