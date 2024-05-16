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

  defmodule Sent do
    typedstruct do
      field :message_id, integer()
      field :time, DateTime.t()
    end

    def new(message_id) do
      %__MODULE__{message_id: message_id, time: DateTime.utc_now()}
    end
  end

  typedstruct module: State do
    field :chat, Chat.t()
    field :members, [User.t()], default: []
    field :sent, Sent.t()
    field :sched_stopped, boolean(), default: true
    # todo: 添加 request 队列
  end

  def namegen(chat_id) do
    {:via, Registry, {EntryManager.Registry, chat_id}}
  end

  def start_link(opts) do
    chat = Keyword.fetch!(opts, :chat)

    GenServer.start(__MODULE__, %State{chat: chat, sent: %Sent{}}, name: namegen(chat.id))
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
      state.sched_stopped && state.sent.time ->
        diff = DateTime.diff(DateTime.utc_now(), state.sent.time, :millisecond)

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
  def handle_cast({:update_sent, sent}, state) do
    {:noreply, %{state | sent: sent}}
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
    last_message_id = state.sent.message_id

    run = fn ->
      members_count = length(members)

      text = """
      有 #{members_count} 个新加入成员正在验证。

      #{DateTime.utc_now()}
      """

      if last_message_id do
        {:ok, _} = async_delete_message(state.chat.id, last_message_id)
      end

      case smart_sender([state.chat.id, text]) do
        {:ok, %{message_id: message_id}} ->
          sent = Sent.new(message_id)
          :ok = GenServer.cast(server, {:update_sent, sent})

        {:error, reason} ->
          Logger.warning("Failed to send entry message: #{inspect(reason)}",
            chat_id: state.chat.id
          )
      end

      _ = Process.send_after(server, :schedule, @interval)
    end

    {:ok, _bee} = Honeycomb.gather_honey(:entry, :anon, run, stateless: true)

    {:noreply, %{state | members: []}}
  end
end

# PolicrMiniBot.ChatEntry.member_joined %PolicrMini.Instances.Chat{id: -1001486769003}, 1
