defmodule PolicrMiniBot.Worker.MessageCleaner do
  @moduledoc """
  负责消息清理的 Worker。

  此模块当前没有加入任务缓存。
  """

  use PolicrMiniBot.Worker

  alias PolicrMini.Logger

  @queue_name :message_cleaner
  @failure_mode {Honeydew.FailureMode.Retry, times: 5}
  @max_concurrency 50

  @type tgerr :: Telegex.Model.errors()

  @impl true
  def init_queue do
    :ok = Honeydew.start_queue(@queue_name, failure_mode: @failure_mode)
    :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
  end

  @impl true
  def job_key(:delete, [chat_id, message_id]) do
    "delete-#{chat_id}-#{message_id}"
  end

  @spec delete(integer | binary, integer | binary) :: {:ok, boolean} | {:error, tgerr}
  def delete(chat_id, message_id) do
    case Telegex.delete_message(chat_id, message_id) do
      {:error, %Telegex.Model.RequestError{reason: reason}} ->
        raise Error,
          message: "Send message delete request failed: #{inspect(reason: reason)}"

      {:error, %{error_code: 400}} = e ->
        # 忽略处理消息不存在的错误
        e

      {:error, reason} = e ->
        Logger.warn(
          "Message deletion failed: #{inspect(reason: reason, chat_id: chat_id, message_id: message_id)}"
        )

        e

      other ->
        other
    end
  end

  @type async_delete_opts :: [{:delay_secs, integer}]

  @spec async_delete(integer, integer, async_delete_opts) :: Honeydew.Job.t() | no_return
  def async_delete(chat_id, message_id, opts \\ []) do
    delay_secs = Keyword.get(opts, :delay_secs, 0)

    fun = {:delete, [chat_id, message_id]}

    Honeydew.async(fun, @queue_name, delay_secs: delay_secs)
  end
end
