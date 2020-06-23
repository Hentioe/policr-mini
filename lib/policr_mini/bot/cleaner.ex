defmodule PolicrMini.Bot.Cleaner do
  @moduledoc """
  提供消息清理服务的模块，委托验证消息发送和删除。
  TODO: 持久化缓存。
  """

  require Logger

  use GenServer

  alias PolicrMini.Bot.Helper

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(_) do
    GenServer.start(__MODULE__, %{vcache: %{}}, name: __MODULE__)
  end

  @impl true
  @doc """
  处理消息的删除请求。
  如果消息因为超时删除失败，将会立即重新删除（当前没有次数限制）。
  TODO: 缓存消息删除次数，如果超过 5 次则不再重试。删除成功清理缓存。
  """
  def handle_cast({:delete, {chat_id, message_id, options}}, state) do
    Helper.async(fn ->
      case Helper.delete_message(chat_id, message_id, options) do
        :ok ->
          nil

        {:error, %Nadia.Model.Error{reason: :timeout} = _error} ->
          # 如果超时，继续删除（删除延迟部分）
          # TODO: 增加延迟删除，时长混入随机数计算
          options = options |> Keyword.delete(:delay_seconds)
          delete_message(chat_id, message_id, options)

        e ->
          Logger.error("Failed to delete message from `#{chat_id}`. Details: #{inspect(e)}")
      end
    end)

    {:noreply, state}
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
    Logger.error("Unknown cast message. Details: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_vcache, chat_id}, _from, state) do
    {:reply, Map.get(state.vcache, chat_id), state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error("Unknown info message. Details: #{inspect(msg)}")

    {:noreply, state}
  end

  @spec get_vcache_message_id(integer()) :: integer() | nil
  @doc """
  获取验证缓存中的消息编号。
  """
  def get_vcache_message_id(chat_id) when is_integer(chat_id) do
    GenServer.call(__MODULE__, {:get_vcache, chat_id})
  end

  @spec delete_vcache_message(integer) :: :ok
  @doc """
  删除缓存中的验证消息。
  """
  def delete_vcache_message(chat_id) when is_integer(chat_id) do
    GenServer.cast(__MODULE__, {:delete_vcache, chat_id})
  end

  @type deleteops :: [{:delay_seconds, integer()}]

  @spec delete_message(integer(), integer(), deleteops()) :: :ok
  @doc """
  删除消息。
  """
  def delete_message(chat_id, message_id, options \\ [])
      when is_integer(chat_id) and is_integer(message_id) and is_list(options) do
    GenServer.cast(__MODULE__, {:delete, {chat_id, message_id, options}})
  end

  @spec clean_expired_verification_message(integer, integer) :: :ok
  @doc """
  清理过期验证消息。
  此函数将删除旧验证消息并自动维护缓存。如果当前消息没有上一个消息编号高，将直接删除当前消息。
  """
  def clean_expired_verification_message(chat_id, current_message_id) do
    if cache_message_id = get_vcache_message_id(chat_id) do
      # 删除旧消息并更新缓存
      if current_message_id > cache_message_id do
        delete_message(chat_id, cache_message_id)
        GenServer.cast(__MODULE__, {:update_vcache, {chat_id, current_message_id}})
      else
        # 本消息已过时
        delete_message(chat_id, current_message_id)
      end
    else
      GenServer.cast(__MODULE__, {:update_vcache, {chat_id, current_message_id}})
    end
  end

  @spec send_verification_message(integer, binary, [
          {:disable_notification, boolean}
          | {:disable_web_page_preview, boolean}
          | {:parse_mode, binary}
          | {:reply_markup, Nadia.Model.InlineKeyboardMarkup.t()}
          | {:retry, integer}
        ]) :: {:error, Nadia.Model.Error.t()} | {:ok, Nadia.Model.Message.t()}
  @doc """
  发送验证消息。
  此函数能自动删除旧消息，并维护缓存。
  """
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

  @spec delete_latest_verification_message(integer) :: :ok | :empty
  @doc """
  删除验证消息。
  此函数会自动维护缓存。
  """
  def delete_latest_verification_message(chat_id)
      when is_integer(chat_id) do
    # 与缓存中的最新消息比对
    if cache_message_id = get_vcache_message_id(chat_id) do
      # 删除缓存
      delete_vcache_message(chat_id)
      # 删除消息
      delete_message(chat_id, cache_message_id)
    else
      :empty
    end
  end
end
