defmodule PolicrMini.StatefulTaskCenter do
  @moduledoc false

  use Supervisor
  use TypedStruct

  alias __MODULE__.{Scheduler, Runner}

  require Logger

  defdelegate schedule(name, fun), to: Scheduler, as: :run

  def jobs do
    state = Scheduler.state()

    state
    |> Enum.into([])
    |> Enum.map(&elem(&1, 1))
  end

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      __MODULE__.Scheduler,
      __MODULE__.Runner
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end

  defmodule Runner do
    @moduledoc false

    use DynamicSupervisor

    def start_link(_) do
      DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
    end

    @impl true
    def init(_init_arg) do
      DynamicSupervisor.init(strategy: :one_for_one)
    end

    def run(name, fun) do
      task = fn ->
        try do
          r = fun.()

          :ok = Scheduler.done(name, r)
        rescue
          e ->
            :ok = Scheduler.failed(name, to_string(e.message))
        end
      end

      DynamicSupervisor.start_child(__MODULE__, {Task, task})
    end
  end

  defmodule Scheduler do
    @moduledoc false

    use GenServer

    typedstruct module: Job do
      @derive Jason.Encoder

      field :name, atom | String.t()
      field :status, :pending | :running | :done
      field :start_at, DateTime.t()
      field :end_at, DateTime.t()
      field :ok, boolean()
      field :result, any()
    end

    @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
    def start_link(_) do
      GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    end

    @impl true
    def init(init_arg) do
      {:ok, init_arg}
    end

    def run(name, fun) when is_function(fun) do
      GenServer.call(__MODULE__, {:run, name, fun})
    end

    def done(name, result) do
      GenServer.cast(__MODULE__, {:job_ok, name, result})
    end

    def failed(name, result) do
      GenServer.cast(__MODULE__, {:job_error, name, result})
    end

    def state do
      GenServer.call(__MODULE__, :state)
    end

    @impl true
    def handle_call({:run, name, fun}, _from, state) do
      if match?(%{status: :running}, Map.get(state, name)) do
        {:reply, {:error, :running}, state}
      else
        job = %Job{name: name, start_at: DateTime.utc_now(), status: :running}

        {:ok, _pid} = Runner.run(name, fun)

        {:reply, :ok, Map.put(state, name, job)}
      end
    end

    @impl true
    def handle_call(:state, _from, state) do
      {:reply, state, state}
    end

    @impl true
    def handle_cast({result_status, name, result}, state)
        when result_status in [:job_ok, :job_error] do
      if job = Map.get(state, name) do
        job = %Job{
          job
          | end_at: DateTime.utc_now(),
            status: :done,
            ok: result_status == :job_ok,
            result: result
        }

        {:noreply, Map.put(state, name, job)}
      else
        # 任务不存在
        Logger.warning("Job not found: #{name}")

        {:noreply, state}
      end
    end
  end
end
