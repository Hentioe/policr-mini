defmodule PolicrMini.Logger do
  @moduledoc """
  查询和记录日志。
  """

  require Logger

  alias :mnesia, as: Mnesia

  @type query_cont :: [{:level, atom}, {:beginning, integer}, {:ending, integer}]

  @spec query(query_cont) :: [PolicrMini.Logger.Record.t()]
  def query(cont \\ []) do
    combiner = fn where, acc ->
      case where do
        {:level, level} -> acc ++ [{:==, :"$1", level}]
        {:beginning, beginning} -> acc ++ [{:>=, :"$3", beginning}]
        {:ending, ending} -> acc ++ [{:"=<", :"$3", ending}]
      end
    end

    guards = Enum.reduce(cont, [], combiner)

    matcher = fn ->
      Mnesia.select(Log, [{{Log, :_, :"$1", :"$2", :"$3"}, guards, [:"$$"]}])
    end

    case Mnesia.transaction(matcher) do
      {:atomic, records} -> records |> Enum.map(&PolicrMini.Logger.Record.new/1) |> Enum.reverse()
    end
  end

  @doc """
  输出格式强制统一的错误日志。

  ## 参数
  - action: 执行失败的动作。位于句首，例如 `The message deletion`（消息删除）。
  - details: 失败的详情。一般是错误的返回值，如要自行定制详情内容推荐传递关键字列表。注意不需要在传递之前调用 `inspect`。

  ## 用例：
      iex> PolicrMini.Logger.unitized_error("The message deletion", chat_id: chat_id, returns: e)
      :ok
      iex> PolicrMini.Logger.unitized_error("Translation search", key: key, raises: e)
      :ok
  """
  @spec unitized_error(String.t(), any) :: :ok
  def unitized_error(action, details) do
    error("#{action} failed, details: #{inspect(details)}")
  end

  defdelegate warn(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate info(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate error(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate debug(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate log(level, chardata_or_fun, metadata \\ []), to: Logger

  defmodule Record do
    @moduledoc """
    可查询的单条日志记录的结构。
    """

    @enforce_keys [:level, :message, :timestamp]
    defstruct level: nil, message: nil, timestamp: nil

    @type t :: %__MODULE__{
            level: atom,
            message: String.t(),
            timestamp: integer
          }

    def new([level, message, timestamp]) do
      %__MODULE__{level: level, message: message, timestamp: timestamp}
    end
  end

  defmodule Backend do
    @moduledoc """
    自定义的日志后端。

    此后端会将日志持久化存储到 Mnesia 中，并可通过 `PolicrMini.Logger.query/1` 函数查询。
    """

    @behaviour :gen_event

    alias :mnesia, as: Mnesia

    def init({__MODULE__, name}) do
      init_mnesia!(name)

      {:ok, configure(name, [])}
    end

    @spec init_mnesia!(atom) :: :ok
    defp init_mnesia!(_name) do
      Mnesia.create_schema([node()])
      :ok = Mnesia.start()

      created_results = [
        Mnesia.create_table(MnesiaSequence,
          attributes: [:name, :value],
          disc_only_copies: [node()]
        ),
        Mnesia.create_table(Log,
          attributes: [:id, :level, :message, :timestamp],
          disc_only_copies: [node()]
        )
      ]

      created_check!(created_results)

      Mnesia.wait_for_tables([MnesiaSequence, Log], 5000)

      :ok
    end

    @spec created_check!([tuple]) :: :ok
    defp created_check!(results) do
      failure_finder = fn result ->
        case result do
          {:atomic, :ok} ->
            false

          {:aborted, {:already_exists, _}} ->
            false

          _ ->
            true
        end
      end

      failed_result = Enum.find(results, failure_finder)

      if failed_result, do: raise(failed_result)

      :ok
    end

    @spec increment(atom) :: integer
    defp increment(name) do
      Mnesia.dirty_update_counter(MnesiaSequence, name, 1)
    end

    defp configure(name, []) do
      base_level = Application.get_env(:logger, name)[:level] || :debug

      Application.get_env(:logger, name, []) |> Enum.into(%{name: name, level: base_level})
    end

    def dirty_write(level, msg, ts) when is_binary(msg) do
      {{year, month, day}, {hour, minute, second, _msec}} = ts

      ts =
        {{year, month, day}, {hour, minute, second}}
        |> NaiveDateTime.from_erl!()
        # 注意：此处的实现表示日志必须使用 UTC 时间
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_unix()

      Mnesia.dirty_write({Log, increment(Log), level, msg, ts})
    end

    def handle_event(:flush, state) do
      {:ok, state}
    end

    # 持久化存储字符串日志消息。
    def handle_event({level, _gl, {Logger, msg, ts, _md}}, %{level: min_level} = state)
        when is_binary(msg) do
      if right_log_level?(min_level, level) do
        dirty_write(level, msg, ts)
      end

      {:ok, state}
    end

    def handle_event(_, state), do: {:ok, state}

    def handle_call({:configure, opts}, %{name: name} = state) do
      {:ok, :ok, configure(name, opts, state)}
    end

    defp configure(_name, [level: new_level], state) do
      Map.merge(state, %{level: new_level})
    end

    defp configure(_name, _opts, state), do: state

    defp right_log_level?(min_level, level) do
      Logger.compare_levels(level, min_level) != :lt
    end
  end
end
