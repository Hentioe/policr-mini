defmodule PolicrMini.Bot.Cleaner do
  @moduledoc """
  提供消息清理服务的模块。
  """

  require Logger

  use GenServer

  alias PolicrMini.Bot.Helper

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(_) do
    GenServer.start(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  @doc """
  处理消息的删除请求。
  如果消息因为超时删除失败，将会立即重新删除（当前没有次数限制）。
  TODO: 缓存消息删除次数，如果超过 3 次则不再重试。删除成功清理缓存。
  """
  def handle_cast({:delete, {chat_id, message_id, options}}, state) do
    Helper.async(fn ->
      case Helper.delete_message(chat_id, message_id, options) do
        :ok ->
          nil

        {:error, %Nadia.Model.Error{reason: :timeout} = _error} ->
          # 如果超时，继续删除（删除延迟部分）
          options = options |> Keyword.delete(:delay_seconds)
          delete_message(chat_id, message_id, options)

        e ->
          Logger.error("Failed to delete message from `#{chat_id}`. Details: #{inspect(e)}")
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast(msg, state) do
    Logger.error("Unknown cast message. Details: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.error("Unknown info message. Details: #{inspect(msg)}")

    {:noreply, state}
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
end
