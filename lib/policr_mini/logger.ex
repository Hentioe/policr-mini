defmodule PolicrMini.Logger do
  @moduledoc """
  查询和记录日志。
  """

  require Logger

  defmodule Record do
    @moduledoc false

    use PolicrMini.Mnesia

    @enforce_keys [:level, :message, :timestamp]
    defstruct [:level, :message, :timestamp]

    @type t :: %__MODULE__{
            level: atom,
            message: String.t(),
            timestamp: integer
          }

    def new([level, message, timestamp]) do
      %__MODULE__{level: level, message: message, timestamp: timestamp}
    end

    @impl true
    def init(node_list) do
      Mnesia.create_table(__MODULE__,
        attributes: [:id, :level, :message, :timestamp],
        disc_only_copies: node_list
      )
    end

    def write(level, msg, ts) when is_binary(msg) do
      {{year, month, day}, {hour, minute, second, _msec}} = ts

      ts =
        {{year, month, day}, {hour, minute, second}}
        |> NaiveDateTime.from_erl!()
        # 注意：此处的实现表示日志必须使用 UTC 时间
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_unix()

      Mnesia.dirty_write({__MODULE__, Sequence.increment(__MODULE__), level, msg, ts})
    end

    @type query_cont :: [
            {:level, atom | nil},
            {:beginning, integer | nil},
            {:ending, integer | nil}
          ]

    @doc """
    查询已持久化存储的日志。

    参数 `query_cont` 表示查询条件，支持以下可选项：
    - `level`: 日志的级别。例如 `:error` 或 `:warn`。
    - `beginning`: 起始时间（时间戳）。
    - `ending`: 结束时间（时间戳）。

    注意：如果不指定时间区间相关的参数，将返回所有的日志记录，这个数据量可能会很庞大。
    """
    @spec query(query_cont) :: {:ok, [t]} | {:error, any}
    def query(cont \\ []) do
      cont_combine_fun = fn where, acc ->
        case where do
          {_, nil} -> acc
          {:level, level} -> acc ++ [{:==, :"$1", level}]
          {:beginning, beginning} -> acc ++ [{:>=, :"$3", beginning}]
          {:ending, ending} -> acc ++ [{:"=<", :"$3", ending}]
        end
      end

      guards = Enum.reduce(cont, [], cont_combine_fun)

      select_fun = fn ->
        Mnesia.select(__MODULE__, [{{__MODULE__, :_, :"$1", :"$2", :"$3"}, guards, [:"$$"]}])
      end

      case Mnesia.transaction(select_fun) do
        {:atomic, records} ->
          records = records |> Enum.map(&new/1) |> Enum.reverse()
          {:ok, records}

        {:aborted, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  输出格式强制统一的错误日志。

  ## 参数
  - `action`: 执行失败的动作。位于句首，例如 `Message deletion`（消息删除）。
  - `details`: 失败的详情。一般是错误的返回值，如要自行定制详情内容推荐使用关键字列表。注意不需要在传递之前调用 `inspect`。
  """
  @spec unitized_error(String.t(), any) :: :ok
  def unitized_error(action, details) do
    error("#{action} failed, details: #{inspect(details)}")
  end

  @doc """
  输出格式强制统一的警告日志。

  ## 参数
  - `message`: 警告消息，语法结构自由，但不要以 `.` 结尾。
  - `defails`: 警告的详情。一般是错误的返回值，如要自行定制详情内容推荐使用关键字列表。注意不需要在传递之前调用 `inspect`。
  """
  @spec unitized_warn(String.t(), any) :: :ok
  def unitized_warn(message, details) do
    warn("#{message}, details: #{inspect(details)}")
  end

  defdelegate warn(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate info(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate error(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate debug(chardata_or_fun, metadata \\ []), to: Logger
  defdelegate log(level, chardata_or_fun, metadata \\ []), to: Logger

  defmodule Backend do
    @moduledoc """
    自定义的日志后端。

    此后端会将日志持久化存储到 Mnesia 中，并可通过 `PolicrMini.Logger.Log.query/1` 函数查询。
    """

    @behaviour :gen_event

    @impl true
    def init({__MODULE__, name}) do
      {:ok, configure(name, [])}
    end

    defp configure(name, []) do
      base_level = Application.get_env(:logger, name)[:level] || :debug

      :logger |> Application.get_env(name, []) |> Enum.into(%{name: name, level: base_level})
    end

    @impl true
    def handle_event(:flush, state) do
      {:ok, state}
    end

    # 持久化存储字符串日志消息。
    def handle_event({level, _gl, {Logger, msg, ts, _md}}, %{level: min_level} = state)
        when is_binary(msg) do
      if right_log_level?(min_level, level) do
        PolicrMini.Logger.Record.write(level, msg, ts)
      end

      {:ok, state}
    end

    def handle_event(_, state), do: {:ok, state}

    @impl true
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
