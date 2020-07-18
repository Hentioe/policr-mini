defmodule PolicrMiniBot.UpdatesPoller do
  @moduledoc """
  获取消息更新的轮训器。
  """

  use GenServer

  require Logger

  alias PolicrMiniBot.Consumer

  @doc """
  启动获取消息更新的轮询器。

  在启动之前会获取机器人自身信息并缓存，并设置初始为 `-1` 的 `offset` 值。
  """
  def start_link(default \\ []) when is_list(default) do
    # 获取机器人必要信息
    Logger.info("Checking bot information…")
    {:ok, %Telegex.Model.User{id: id, username: username}} = Telegex.get_me()
    Logger.info("Bot (@#{username}) is working")
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

  @doc """
  处理异步消息。

  每收到一次 `:pull` 消息，就获取下一次更新，并修改状态中的 `offset` 值。
  如果收到 `{:ssl_closed, _}` 消息，会输出错误日志，但目前没有做任何网络检查或试图挽救的措施。
  """
  @impl true
  def handle_info(:pull, %{offset: last_offset} = state) do
    offset =
      case Telegex.get_updates(offset: last_offset) do
        {:ok, updates} ->
          # 消费消息
          updates |> Enum.each(fn update -> Consumer.receive(update) end)
          # 获取新的 offset
          if length(updates) > 0,
            do: List.last(updates).update_id + 1,
            else: last_offset

        e ->
          Logger.error("An error occurred while pulling updates, details: #{inspect(e)}")
          last_offset
      end

    if offset == last_offset, do: :timer.sleep(500), else: :timer.sleep(200)
    schedule_pull_updates()
    {:noreply, %{state | offset: offset}}
  end

  @impl true
  def handle_info({:ssl_closed, _} = details, state) do
    Logger.error("An SSL error occurred while pulling updates, details: #{inspect(details)}")

    {:noreply, state}
  end

  defp schedule_pull_updates do
    send(self(), :pull)
  end
end
