defmodule PolicrMini.Stats do
  @moduledoc false

  alias PolicrMini.{Uses, Chats, InfluxConn}
  alias PolicrMini.Chats.Verification

  require Logger

  use TypedStruct

  @type query_opts :: [
          chat_id: integer(),
          start: String.t(),
          every: String.t()
        ]

  typedstruct module: FluxError do
    field :code, String.t()
    field :message, String.t()
  end

  defmodule MinimizedPoint do
    @moduledoc false

    typedstruct do
      field :time, DateTime
      field :status, String.t()
      field :count, integer
    end

    def from(%{"_time" => time, "status" => status, "_value" => value}) do
      %__MODULE__{time: DateTime.from_unix!(time, :nanosecond), status: status, count: value}
    end
  end

  typedstruct module: QueryResult do
    field :start, String.t()
    field :every, String.t()
    field :chat_id, integer
    field :points, [MinimizedPoint.t()]
  end

  defmodule WritePoint do
    @moduledoc false

    typedstruct do
      field :measurement, String.t(), enforce: true
      field :fields, %{atom => any}, enforce: true
      field :tags, %{atom => any}, enforce: true
      field :timestamp, DateTime.t(), enforce: true
    end

    @type status :: :approved | :incorrect | :timeout | :other
    @type source :: :joined | :join_request
  end

  defmodule GenResult do
    @moduledoc false

    @derive Jason.Encoder

    typedstruct do
      field :success, integer(), default: 0
      field :failure, integer(), default: 0
    end

    def merge(self, another)
        when is_struct(self, __MODULE__) and is_struct(another, __MODULE__) do
      %{self | success: self.success + another.success, failure: self.failure + another.failure}
    end
  end

  @type write_result :: :ok | {:error, FluxError.t()}

  @spec write(any) :: write_result
  def write(point) when is_struct(point, WritePoint) do
    point = %{
      measurement: point.measurement,
      fields: point.fields,
      timestamp: DateTime.to_unix(point.timestamp, :nanosecond),
      tags: point.tags
    }

    case PolicrMini.InfluxConn.write(point) do
      :ok ->
        :ok

      %{code: code, message: message} ->
        {:error, %FluxError{code: code, message: message}}
    end
  end

  @doc """
  写入一个验证数据点。
  """
  def write(v) when is_struct(v, Verification) do
    status =
      case v.status do
        :passed -> :approved
        :wronged -> :incorrect
        :timeout -> :timeout
        _ -> :other
      end

    point = %WritePoint{
      measurement: "verifications",
      fields: %{
        count: 1
      },
      tags: %{
        chat_id: v.chat_id,
        user_id: v.target_user_id,
        user_language_code: v.target_user_language_code,
        status: to_string(status),
        source: to_string(v.source)
      },
      timestamp: v.updated_at
    }

    write(point)
  end

  @doc """
  查询指定群组特定范围内的验证次数统计。
  """
  @deprecated "Use PolicrMini.Stats.query/1 instead"
  def query(chat_id, opts)
      when (is_integer(chat_id) or is_binary(chat_id)) and is_list(opts) do
    query(Keyword.put(opts, :chat_id, chat_id))
  end

  @doc """
  查询验证次数统计。

  ## 可选参数：
    - `chat_id`: 群聊 ID。
    - `start`: 查询的起始时间，默认为 `-1d`。
    - `every`: 查询的时间间隔，默认为 `1d`。
  """
  @spec query(query_opts()) :: {:ok, QueryResult.t()} | {:error, FluxError.t()}
  def query(opts \\ []) when is_list(opts) do
    # TODO: 添加对字段的安全检查
    chat_id = Keyword.get(opts, :chat_id)
    start = Keyword.get(opts, :start, "-1d")
    every = Keyword.get(opts, :every, "1d")

    filter =
      if chat_id do
        ~s(r._measurement == "verifications" and r._field == "count" and r.chat_id == "#{chat_id}")
      else
        ~s(r._measurement == "verifications" and r._field == "count")
      end

    flux =
      ~s{
      from(bucket: "#{InfluxConn.config(:bucket)}")
        |> range(start: #{start})
        |> filter(fn: (r) => #{filter})
        |> group(columns: ["status", "count"])
        |> aggregateWindow(every: #{every}, fn: sum)
        |> keep(columns: ["_time", "status", "_value"])
      }

    case InfluxConn.query(flux, org: InfluxConn.config(:org)) do
      {:code, message} ->
        {:error, %FluxError{message: message}}

      r ->
        points = Enum.map(r, &__MODULE__.MinimizedPoint.from/1)

        {:ok,
         %QueryResult{
           start: start,
           every: every,
           chat_id: chat_id,
           points: points
         }}
    end
  end

  @doc """
  重新生成特定群组最近指定天数的统计数据。
  """
  @spec regen_recent_days(integer, integer) :: GenResult.t()
  def regen_recent_days(chat_id, days) do
    stop = DateTime.utc_now()
    start = DateTime.add(stop, -days, :day)

    regen(chat_id, start, stop)
  end

  @doc """
  从指定时间区间重新生成统计数据。
  """
  @spec regen(integer, DateTime.t(), DateTime.t()) :: GenResult.t()
  def regen(chat_id, start, stop) do
    # 清空此时间段的时序数据
    delete_by_time_range(chat_id, start, stop)
    # 从此时间段的验证记录中重新生成时序数据
    # todo: 根据时区偏移
    # todo: 批量写入
    chat_id
    |> Chats.range_verifications(start, stop)
    |> Stream.map(&write/1)
    |> Enum.reduce(%GenResult{}, fn
      :ok, result ->
        %{result | success: result.success + 1}

      {:error, reason}, result ->
        Logger.error("Write verification point failed: #{inspect(reason)}", chat_id: chat_id)
        %{result | error: result.error + 1}
    end)
  end

  @spec delete_by_time_range(integer, DateTime.t(), DateTime.t()) :: :ok
  def delete_by_time_range(chat_id, start, stop) do
    PolicrMini.InfluxConn.delete(%{
      start: DateTime.to_iso8601(start),
      stop: DateTime.to_iso8601(stop),
      predicate: ~s(_measurement="verifications" and chat_id="#{chat_id}")
    })

    :ok
  end

  def clear_all(chat_id) do
    delete_by_time_range(chat_id, ~U[1970-01-01T00:00:00.00Z], DateTime.utc_now())
  end

  @doc """
  重置特定群组最近的统计数据（一个月）。
  """
  def reset_recently(chat_id) do
    # 清空此群组的所有统计数据
    :ok = clear_all(chat_id)
    # 重新生成最近一个月的数据
    regen_recent_days(chat_id, 30)
  end

  def reset_all_stats do
    chats = Uses.all_chats()

    results =
      for chat <- chats do
        # 清空此群组的所有统计数据
        :ok = clear_all(chat.id)
        # 重新生成最近 99 年的数据
        regen_recent_days(chat.id, 365 * 99)
      end

    result = Enum.reduce(results, %GenResult{}, &GenResult.merge/2)

    %{chats: length(chats), success: result.success, failure: result.failure}
  end
end
