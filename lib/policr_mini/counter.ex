defmodule PolicrMini.Counter do
  @moduledoc """
  计数器缓存实现。
  """

  use GenServer

  import PolicrMini.Helper

  alias PolicrMini.VerificationBusiness
  alias :mnesia, as: Mnesia

  def start_link(_opts) do
    state = %{
      verification_total: VerificationBusiness.find_total(),
      verification_passed_total: VerificationBusiness.find_total(status: :passed),
      verification_timeout_total: VerificationBusiness.find_total(status: :timeout)
    }

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(state) do
    %{
      verification_total: verification_total,
      verification_passed_total: verification_passed_total,
      verification_timeout_total: verification_timeout_total
    } = state

    node_list = init_mnesia!()

    table_result =
      Mnesia.create_table(Counter,
        attributes: [:key, :value],
        ram_copies: node_list
      )

    check_mnesia_created_table!(table_result)

    Mnesia.wait_for_tables([Counter], 2000)
    Mnesia.dirty_write({Counter, :verification_total, verification_total})
    Mnesia.dirty_write({Counter, :verification_passed_total, verification_passed_total})
    Mnesia.dirty_write({Counter, :verification_timeout_total, verification_timeout_total})

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
    value =
      case Mnesia.dirty_read(Counter, key) do
        [{Counter, _key, value}] -> value
        [] -> -1
      end

    {:reply, value, state}
  end

  @impl true
  def handle_cast({:increment, key}, state) do
    Mnesia.dirty_update_counter(Counter, key, 1)

    {:noreply, state}
  end
end
