defmodule PolicrMini.Bot do
  use GenServer

  alias __MODULE__.Consumer

  def start_link(default \\ []) when is_list(default) do
    # 获取机器人必要信息
    {:ok, %Nadia.Model.User{id: id, username: username}} = Nadia.get_me()
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
      case Nadia.get_updates(offset: last_offset) do
        {:ok, updates} ->
          # 消费消息
          updates |> Enum.each(fn update -> Consumer.receive(update) end)
          # 获取新的 offset
          if length(updates) > 0,
            do: List.last(updates).update_id + 1,
            else: last_offset

        _ ->
          last_offset
      end

    if offset == last_offset, do: :timer.sleep(500), else: :timer.sleep(200)
    schedule_pull_updates()
    {:noreply, %{state | offset: offset}}
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
