defmodule PolicrMini.Mnesia do
  @moduledoc false

  # TODO: 此模块中可能存在一些需要清理的残余代码（如日志相关）。

  alias :mnesia, as: Mnesia

  alias PolicrMini.Counter.State, as: CounterState
  alias __MODULE__.Sequence

  defmodule Table do
    @moduledoc false

    @callback init([node]) :: {:atomic, any} | {:aborted, any}
  end

  defmacro __using__(_) do
    quote do
      alias :mnesia, as: Mnesia
      alias PolicrMini.Mnesia.Sequence

      @behaviour PolicrMini.Mnesia.Table
    end
  end

  def init do
    node_list = [node()]

    Mnesia.create_schema(node_list)
    Mnesia.start()

    :ok = check_init(Sequence, node_list)
    :ok = check_init(CounterState, node_list)

    Mnesia.wait_for_tables([Sequence, LoggerRecord, CounterState], 5000)

    :ok
  end

  def check_init(module, node_list) do
    case module.init(node_list) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, _}} -> :ok
      other -> other
    end
  end
end

defmodule PolicrMini.Mnesia.Sequence do
  @moduledoc false

  use PolicrMini.Mnesia

  @impl true
  def init(node_list) do
    Mnesia.create_table(__MODULE__,
      attributes: [:name, :value],
      disc_only_copies: node_list
    )
  end

  @spec increment(atom) :: integer
  def increment(key) do
    Mnesia.dirty_update_counter(__MODULE__, key, 1)
  end
end
