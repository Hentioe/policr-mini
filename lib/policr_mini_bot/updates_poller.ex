defmodule PolicrMiniBot.UpdatesPoller do
  @moduledoc """
  获取消息更新的轮询服务。
  """

  use GenServer

  alias PolicrMini.Logger
  alias PolicrMiniBot.Consumer

  @doc """
  启动获取消息更新的轮询器。

  在启动之前会获取机器人自身信息并缓存，并设置初始为 `0` 的 `offset` 值。
  """
  def start_link(default \\ []) when is_list(default) do
    # 获取机器人必要信息
    Logger.info("Checking bot information…")
    {:ok, %Telegex.Model.User{id: id, username: username}} = Telegex.get_me()
    Logger.info("Bot (@#{username}) is working")
    # 更新 Plug 中缓存的用户名
    Telegex.Plug.update_username(username)
    # 缓存机器人数据
    :ets.new(:bot_info, [:set, :named_table])
    :ets.insert(:bot_info, {:id, id})
    :ets.insert(:bot_info, {:username, username})

    GenServer.start_link(__MODULE__, %{offset: 0}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_pull_updates()
    {:ok, state}
  end

  @doc """
  处理异步消息。

  每收到一次 `:pull` 消息，就获取下一次更新，并修改状态中的 `offset` 值。
  """
  @impl true
  def handle_info(:pull, %{offset: last_offset} = state) do
    offset =
      case Telegex.get_updates(offset: last_offset) do
        {:ok, updates} ->
          # 消费消息
          updates |> Enum.each(&Consumer.receive/1)

          if Enum.empty?(updates),
            do: last_offset,
            # 获取新的 offset
            else: List.last(updates).update_id + 1

        e ->
          Logger.unitized_error("Message pull", e)
          # 发生错误，降低请求频率
          :timer.sleep(50)
          last_offset
      end

    schedule_pull_updates()
    {:noreply, %{state | offset: offset}}
  end

  #  如果收到 `{:ssl_closed, _}` 消息，会输出错误日志，目前没有做任何网络检查或试图挽救的措施。
  @impl true
  def handle_info({:ssl_closed, _} = msg, state) do
    Logger.unitized_error("SSL connection", msg)

    {:noreply, state}
  end

  defp schedule_pull_updates do
    send(self(), :pull)
  end
end
