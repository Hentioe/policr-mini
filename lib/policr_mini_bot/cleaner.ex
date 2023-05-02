defmodule PolicrMiniBot.Cleaner do
  @moduledoc """
  提供消息清理服务的模块，委托验证消息发送和删除。
  """

  use GenServer

  alias PolicrMiniBot.{Helper, Worker}

  require Logger

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(_) do
    GenServer.start(__MODULE__, %{vcache: %{}}, name: __MODULE__)
  end

  @impl true
  def handle_cast({:update_vcache, {chat_id, message_id}}, state) do
    vcache = Map.put(state.vcache, chat_id, message_id)
    {:noreply, %{state | vcache: vcache}}
  end

  @impl true
  def handle_cast({:delete_vcache, chat_id}, state) do
    vcache = Map.delete(state.vcache, chat_id)
    {:noreply, %{state | vcache: vcache}}
  end

  @impl true
  def handle_cast(msg, state) do
    Logger.warning("The cleaner received an unknown cast message: #{inspect(msg)}")

    {:noreply, state}
  end

  @impl true
  def handle_call({:get_vcache, chat_id}, _from, state) do
    {:reply, Map.get(state.vcache, chat_id), state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("The cleaner received an unknown cast message: #{inspect(msg)}")

    {:noreply, state}
  end

  @doc """
  获取验证缓存中的消息编号。
  """
  @spec get_vcache_message_id(integer()) :: integer() | nil
  def get_vcache_message_id(chat_id) when is_integer(chat_id) do
    GenServer.call(__MODULE__, {:get_vcache, chat_id})
  end

  @doc """
  删除缓存中的验证消息。
  """
  @spec delete_vcache_message(integer) :: :ok
  def delete_vcache_message(chat_id) when is_integer(chat_id) do
    GenServer.cast(__MODULE__, {:delete_vcache, chat_id})
  end

  @type deleteops :: [{:delay_seconds, integer()}]

  @doc """
  清理过期验证消息。

  此函数将删除旧验证消息并自动维护缓存。如果当前消息没有上一个消息编号高，将直接删除当前消息。
  """
  @spec clean_expired_verification_message(integer, integer) :: :ok
  def clean_expired_verification_message(chat_id, current_message_id) do
    if cache_message_id = get_vcache_message_id(chat_id) do
      if current_message_id > cache_message_id do
        # 删除旧消息
        Worker.async_delete_message(chat_id, cache_message_id)
        # 更新缓存
        GenServer.cast(__MODULE__, {:update_vcache, {chat_id, current_message_id}})
      else
        # 消息已过时
        Worker.async_delete_message(chat_id, current_message_id)
      end
    else
      GenServer.cast(__MODULE__, {:update_vcache, {chat_id, current_message_id}})
    end
  end

  @type send_verification_message_opts :: [
          {:disable_notification, boolean}
          | {:disable_web_page_preview, boolean}
          | {:parse_mode, binary}
          | {:reply_markup, Telegex.Model.InlineKeyboardMarkup.t()}
          | {:retry, integer}
        ]

  @doc """
  发送验证消息。

  此函数能自动删除旧消息，并维护缓存。
  """
  @spec send_verification_message(integer, binary, send_verification_message_opts) ::
          {:error, Telegex.Model.errors()} | {:ok, Telegex.Model.Message.t()}
  def send_verification_message(chat_id, text, options \\ [])
      when is_integer(chat_id) and is_list(options) do
    case Helper.send_message(chat_id, text, options) do
      {:ok, %{message_id: message_id}} = r ->
        clean_expired_verification_message(chat_id, message_id)

        r

      e ->
        e
    end
  end

  @doc """
  删除验证消息。

  此函数会自动维护缓存。
  """
  @spec delete_latest_verification_message(integer) :: :ok | :empty
  def delete_latest_verification_message(chat_id)
      when is_integer(chat_id) do
    # 与缓存中的最新消息比对
    if cache_message_id = get_vcache_message_id(chat_id) do
      # 删除缓存
      delete_vcache_message(chat_id)
      # 删除消息
      Worker.async_delete_message(chat_id, cache_message_id)
    else
      :empty
    end
  end
end
