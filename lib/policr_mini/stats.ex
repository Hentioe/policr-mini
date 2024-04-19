defmodule PolicrMini.Stats do
  @moduledoc false

  alias PolicrMini.{Chats, InfluxConn, Serveds}
  alias PolicrMini.Chats.Verification

  require Logger

  use TypedStruct

  typedstruct module: FluxError do
    field :code, String.t()
    field :message, String.t()
  end

  defmodule MinimizedPoint do
    @moduledoc false

    typedstruct do
      @derive Jason.Encoder

      field :time, DateTime
      field :status, String.t()
      field :count, integer
    end

    def from(%{"_time" => time, "status" => status, "_value" => value}) do
      %__MODULE__{time: DateTime.from_unix!(time, :nanosecond), status: status, count: value}
    end
  end

  typedstruct module: QueryResult do
    @derive Jason.Encoder

    field :start, String.t()
    field :every, String.t()
    field :chat_id, integer
    field :points, [MinimizedPoint.t()]
  end

  defmodule WritePoint do
    typedstruct do
      @derive Jason.Encoder

      field :measurement, String.t(), enforce: true
      field :fields, %{atom => any}, enforce: true
      field :tags, %{atom => any}, enforce: true
      field :timestamp, DateTime.t(), enforce: true
    end

    @type verf_status :: :passed | :rejected | :timeout | :other
    @type verf_source :: :joined | :join_request
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

  # 写入一个验证数据点。
  def write(v) when is_struct(v, Verification) do
    status =
      case v.status do
        :passed -> :passed
        :wronged -> :rejected
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
      timestamp: DateTime.utc_now()
    }

    write(point)
  end

  @doc """
  查询指定群组特定范围内的验证次数统计。

  ## 参数
    - `chat_id`: 群聊 ID。
  ## 可选参数：
    - `start`: 查询的起始时间，默认为 `-7d`。
    - `every`: 查询的时间间隔，默认为 `1d`。
  """
  @spec query(integer, keyword) :: {:ok, QueryResult.t()} | {:error, FluxError.t()}
  def query(chat_id, opts \\ []) do
    # TODO: 添加对字段的安全检查
    start = Keyword.get(opts, :start, "-7d")
    every = Keyword.get(opts, :every, "1d")

    flux =
      ~s{
      from(bucket: "#{InfluxConn.config(:bucket)}")
        |> range(start: #{start})
        |> filter(fn: (r) => r._measurement == "verifications" and r._field == "count" and r.chat_id == "#{chat_id}")
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
  重新生成最近一周。
  """
  @spec regen_recent_week(integer) :: :ok
  def regen_recent_week(chat_id) do
    dtart = DateTime.utc_now()
    dend = DateTime.add(dtart, -7, :day)

    regen(chat_id, dtart, dend)
  end

  @doc """
  从指定时间区间重新生成统计数据。
  """
  @spec regen(integer, DateTime.t(), DateTime.t()) :: :ok
  def regen(chat_id, dstart, dend) do
    # 清空此时间段的时序数据
    delete_by_time_range(chat_id, dstart, dend)
    # 从此时间段的验证记录中重新生成时序数据
    # todo: 加上时区
    verfs = Chats.time_range_verfs(chat_id, dstart, dend)

    # todo: 批量写入时序数据
    verfs
    |> Stream.each(&write/1)
    |> Stream.run()

    :ok
  end

  @spec delete_by_time_range(integer, DateTime.t(), DateTime.t()) :: :ok
  def delete_by_time_range(chat_id, dstart, dend) do
    PolicrMini.InfluxConn.delete(%{
      start: DateTime.to_iso8601(dstart),
      stop: DateTime.to_iso8601(dend),
      predicate: ~s(_measurement="verifications" and chat_id="#{chat_id}")
    })

    :ok
  end

  def clear_all(chat_id) do
    delete_by_time_range(chat_id, ~U[1970-01-01T00:00:00.00Z], DateTime.utc_now())
  end

  @doc """
  重置指定群组的统计数据（仅生成最近的数据）。
  """
  def reset_recently(chat_id) do
    # 清空此群组的所有数据
    :ok = clear_all(chat_id)
    # 重新生成最近一周的数据
    :ok = regen_recent_week(chat_id)
  end

  def reset_all_stats do
    for chat <- Serveds.find_takeovered_chats() do
      reset_recently(chat.id)
    end
  end
end
