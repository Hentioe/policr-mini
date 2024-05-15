defmodule PolicrMiniBot.EntryManager do
  @moduledoc false

  use DynamicSupervisor

  alias PolicrMini.Instances.Chat
  alias PolicrMiniBot.ChatEntry

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def chat_entry(chat) when is_struct(chat, Chat) do
    server = ChatEntry.namegen(chat.id)

    with nil <- GenServer.whereis(server),
         {:ok, pid} <- DynamicSupervisor.start_child(__MODULE__, {ChatEntry, chat: chat}) do
      pid
    else
      pid when is_pid(pid) -> pid
    end
  end
end
