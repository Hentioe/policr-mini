defmodule PolicrMini.Bot do
  use GenServer

  require Logger

  alias __MODULE__.Consumer

  def start_link(default \\ []) when is_list(default) do
    # 获取机器人必要信息
    {:ok, %Telegex.Model.User{id: id, username: username}} = Telegex.get_me()
    # 缓存机器人数据
    :ets.new(:bot_info, [:set, :named_table])
    :ets.insert(:bot_info, {:id, id})
    :ets.insert(:bot_info, {:username, username})

    GenServer.start_link(__MODULE__, %{offset: -1}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_pull_updates()
    {:ok, state}
  end

  @impl true
  def handle_info(:pull, state = %{offset: last_offset}) do
    offset =
      case Telegex.get_updates(offset: last_offset) do
        {:ok, updates} ->
          # 消费消息
          updates |> Enum.each(fn update -> Consumer.receive(update) end)
          # 获取新的 offset
          if length(updates) > 0,
            do: List.last(updates).update_id + 1,
            else: last_offset

        _e ->
          # TODO: 因为网络 timeout 问题太频繁，忽略记录日志。有待解决。
          # E.g: {:error, %Telegex.Model.RequestError{reason: :timeout}}
          # Logger.error("An error occurred while pulling updates, details: #{inspect(e)}")
          last_offset
      end

    if offset == last_offset, do: :timer.sleep(500), else: :timer.sleep(200)
    schedule_pull_updates()
    {:noreply, %{state | offset: offset}}
  end

  @doc """
  忽略拉取消息时产生的 SSL 错误
  TODO: 因为 SSL 问题太频繁，忽略记录日志。有待解决。
  E.g: {:ssl_closed, {:sslsocket, {:gen_tcp, #Port<0.464>, :tls_connection, :undefined}, [#PID<0.9807.0>, #PID<0.9806.0>]}}
  """
  @impl true
  def handle_info({:ssl_closed, _} = _details, state) do
    # Logger.error("An SSL error occurred while pulling updates, details: #{inspect(details)}")

    {:noreply, state}
  end

  def id() do
    [{:id, id}] = :ets.lookup(:bot_info, :id)

    id
  end

  def username() do
    [{:username, username}] = :ets.lookup(:bot_info, :username)

    username
  end

  defp schedule_pull_updates do
    send(self(), :pull)
  end
end
