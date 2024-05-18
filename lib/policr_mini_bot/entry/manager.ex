defmodule PolicrMiniBot.Entry.Manager do
  @moduledoc false

  use DynamicSupervisor

  require Logger

  alias PolicrMini.Instances.Chat
  alias PolicrMiniBot.Entry.Maintainer

  import PolicrMiniBot.Entry.Helper

  def start_link(_) do
    :ok = init_table()

    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def maintainer(chat) when is_struct(chat, Chat) do
    server = Maintainer.namegen(chat.id)

    with nil <- GenServer.whereis(server),
         {:ok, pid} <- DynamicSupervisor.start_child(__MODULE__, {Maintainer, chat: chat}) do
      pid
    else
      pid when is_pid(pid) ->
        pid

      {:error, reason} ->
        raise "Failed to start entry maintainer: #{inspect(chat_id: chat.id, reason: reason)}"
    end
  end
end
