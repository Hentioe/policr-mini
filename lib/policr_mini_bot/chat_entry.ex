defmodule PolicrMiniBot.ChatEntry do
  @moduledoc false

  use GenServer
  use TypedStruct

  import PolicrMiniBot.Helper

  require Logger

  alias PolicrMini.Instances.Chat
  alias PolicrMiniBot.EntryManager
  alias Telegex.Type.User

  @interval 2000

  typedstruct module: State do
    field :chat, Chat.t()
    field :members, [User.t()], default: []
    field :last_sent_time, DateTime.t()
    field :last_message_id, DateTime.t()
    field :sched_stopped, boolean(), default: true
    # todo: 添加 request 队列
  end

  def namegen(chat_id) do
    {:via, Registry, {EntryManager.Registry, chat_id}}
  end

  def start_link(opts) do
    chat = Keyword.fetch!(opts, :chat)

    GenServer.start(__MODULE__, %State{chat: chat}, name: namegen(chat.id))
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  def member_joined(chat, user) do
    GenServer.cast(EntryManager.chat_entry(chat), {:member_joined, user})
  end

  @impl true
  def handle_cast({:member_joined, user}, state) do
    members = [user | state.members]

    cond do
      state.sched_stopped && state.last_sent_time ->
        diff = DateTime.diff(DateTime.utc_now(), state.last_sent_time, :millisecond)

        if diff > @interval do
          # 如果调度未开始，且与上次的发送时间的间隔大于 `@interval`，立即调度。
          Logger.debug("Entry schedule immediately triggered", chat_id: state.chat.id)

          :ok = Process.send(self(), :schedule, [])
        else
          # 如果小于 1 秒，等待 1 秒后再调度。
          Logger.debug("Entry schedule delayed triggered", chat_id: state.chat.id)
          _ = Process.send_after(self(), :schedule, @interval)
        end

      state.sched_stopped ->
        # 如果调度未开始，且上次发送时间为空，立即调度。
        Logger.debug("Entry schedule immediately triggered", chat_id: state.chat.id)
        :ok = Process.send(self(), :schedule, [])

      true ->
        :ingore
    end

    {:noreply, %{state | members: members, sched_stopped: false}}
  end

  @impl true
  def handle_cast({:update_message_id, message_id}, state) do
    {:noreply, %{state | last_message_id: message_id}}
  end

  @impl true
  def handle_cast({:update_last_sent_time, dt}, state) do
    {:noreply, %{state | last_sent_time: dt}}
  end

  @impl true
  def handle_info(:schedule, %{members: members} = state) when members == [] do
    # 成员列表是空的，停止调度。
    Logger.debug("Entry scheduler stopped", chat_id: state.chat.id)

    {:noreply, %{state | sched_stopped: true}}
  end

  @impl true
  def handle_info(:schedule, %{members: members} = state) do
    # 合并成员列表为单条消息内容，发送或编辑消息。
    Logger.debug("Entry scheduler triggered", chat_id: state.chat.id)

    server = self()
    last_message_id = state.last_message_id

    run = fn ->
      members_count = length(members)

      text = """
      有 #{members_count} 个新加入成员正在验证。

      #{DateTime.utc_now()}
      """

      {method, args} =
        if last_message_id do
          {:edit_message_text, [text, [chat_id: state.chat.id, message_id: last_message_id]]}
        else
          {:send_message, [state.chat.id, text]}
        end

      case smart_sender(method, args) do
        {:ok, %{message_id: message_id}} ->
          :ok = GenServer.cast(server, {:update_message_id, message_id})
          :ok = GenServer.cast(server, {:update_last_sent_time, message_id})

        {:error, reason} ->
          Logger.warning("Failed to send message: #{inspect(reason)}", chat_id: state.chat.id)
      end

      _ = Process.send_after(server, :schedule, @interval)
    end

    {:ok, _bee} = Honeycomb.gather_honey(:entry, :anon, run, stateless: true)

    {:noreply, %{state | members: []}}
  end
end
