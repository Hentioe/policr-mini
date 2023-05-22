defmodule PolicrMiniBot.EntryMaintainer do
  @moduledoc false

  use GenServer
  use PolicrMiniBot.MessageCaller

  alias PolicrMiniBot.Worker

  require Logger

  @type state :: %{integer => integer}
  @type caller :: MessageCaller.caller()
  @type put_opts :: MessageCaller.call_opts()

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  发送或替换入口消息。

  此函数会自动维护每个群聊入口消息的单一性，缓存最新的入口消息并删除过期入口消息。
  """
  @spec put_entry_message(caller, integer, put_opts) :: MessageCaller.call_result()
  def put_entry_message(caller, chat_id, optional) do
    case MessageCaller.call(caller, chat_id, optional) do
      {:ok, %{message_id: message_id}} = ok_r ->
        # 清理过期的入口消息
        clear_expired_entry_message(chat_id, message_id)

        ok_r

      e ->
        e
    end
  end

  @spec delete_entry_message(integer) :: :ok
  def delete_entry_message(chat_id) do
    if last_message_id = get_message_id(chat_id) do
      # 删除消息 ID
      :ok = delete_message_id(chat_id)
      # 异步删除消息
      Worker.async_delete_message(chat_id, last_message_id)
    end

    :ok
  end

  @spec clear_expired_entry_message(integer, integer) :: :ok
  defp clear_expired_entry_message(chat_id, current_message_id) do
    if last_message_id = get_message_id(chat_id) do
      cond do
        last_message_id < current_message_id ->
          # 当前消息在上一条消息之后，删除旧消息
          Worker.async_delete_message(chat_id, last_message_id)

          # 更新消息 ID
          :ok = put_message_id(chat_id, current_message_id)

        last_message_id > current_message_id ->
          # 当前消息在最新消息之前，已过时，直接删除
          Worker.async_delete_message(chat_id, current_message_id)

          :ok

        true ->
          # 此处一般是编辑后的消息（消息 ID 没变化），什么也不做
          :ok
      end
    else
      # 不存在上一条消息，直接更新消息 ID
      :ok = put_message_id(chat_id, current_message_id)
    end
  end

  defp get_message_id(chat_id) do
    GenServer.call(__MODULE__, {:get_message_id, chat_id})
  end

  defp put_message_id(chat_id, message_id) do
    GenServer.cast(__MODULE__, {:put_message_id, chat_id, message_id})
  end

  defp delete_message_id(chat_id) do
    GenServer.cast(__MODULE__, {:delete_message_id, chat_id})
  end

  @impl true
  def handle_call({:get_message_id, chat_id}, _from, state) do
    {:reply, Map.get(state, chat_id), state}
  end

  @impl true
  def handle_cast({:put_message_id, chat_id, message_id}, state) do
    {:noreply, Map.put(state, chat_id, message_id)}
  end

  @impl true
  def handle_cast({:delete_message_id, chat_id}, state) do
    {:noreply, Map.delete(state, chat_id)}
  end
end
