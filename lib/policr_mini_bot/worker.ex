defmodule PolicrMiniBot.Worker do
  @moduledoc false

  # TODO: 持久化缓存。

  alias PolicrMini.Logger

  defmodule Error do
    defexception [:message]
  end

  @message_cleaner_queue_name :message_cleaner
  @message_cleaner_failure_mode {Honeydew.FailureMode.Retry, times: 5}
  @message_cleaner_max_concurrency 50

  def delete_message(chat_id, message_id) do
    case Telegex.delete_message(chat_id, message_id) do
      {:error, %Telegex.Model.RequestError{reason: reason}} ->
        raise Error, message: "Failed to send delete message request, reason: #{reason}"

      {:error, e} ->
        Logger.warn(
          "Failed to delete message, details: #{inspect(error: e, chat_id: chat_id, message_id: message_id)}"
        )

      other ->
        other
    end
  end

  @type async_delete_message_opts :: [{:delay_secs, integer}]

  @doc """
  异步删除消息。

  消息删除失败会自动重试三次。

  ## 可选参数
    - `delay_secs`: 延迟删除的秒数。
  """
  @spec async_delete_message(integer, integer, async_delete_message_opts) ::
          Honeydew.Job.t() | no_return
  def async_delete_message(chat_id, message_id, opts \\ []) do
    delay_secs = Keyword.get(opts, :delay_secs, 0)

    fun = {:delete_message, [chat_id, message_id]}

    Honeydew.async(fun, @message_cleaner_queue_name, delay_secs: delay_secs)
  end

  def init_message_cleaner_queue do
    :ok =
      Honeydew.start_queue(@message_cleaner_queue_name,
        failure_mode: @message_cleaner_failure_mode
      )

    :ok =
      Honeydew.start_workers(@message_cleaner_queue_name, PolicrMiniBot.Worker,
        num: @message_cleaner_max_concurrency
      )
  end
end
