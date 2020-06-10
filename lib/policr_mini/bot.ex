defmodule PolicrMini.Bot do
  use GenServer

  alias __MODULE__.Consumer

  def start_link(default \\ []) when is_list(default) do
    {:ok, %Nadia.Model.User{username: username}} = Nadia.get_me()
    GenServer.start_link(__MODULE__, %{offset: -1, username: username}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_pull_updates()
    {:ok, state}
  end

  @impl true
  def handle_info(:pull, state = %{offset: last_offset, username: username}) do
    offset =
      case Nadia.get_updates(offset: last_offset) do
        {:ok, updates} ->
          # 消费消息
          updates |> Enum.each(fn update -> Consumer.receive(update, username) end)
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

  defp schedule_pull_updates do
    send(self(), :pull)
  end
end
