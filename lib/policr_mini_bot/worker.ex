defmodule PolicrMiniBot.Worker do
  @moduledoc false

  # TODO: 持久化缓存。

  alias PolicrMini.Logger

  defmodule Error do
    defexception [:message]
  end

  defmodule MessageCleaner do
    @moduledoc false

    @queue_name :message_cleaner
    @failure_mode {Honeydew.FailureMode.Retry, times: 5}
    @max_concurrency 50

    def delete(chat_id, message_id) do
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

    @type async_delete_opts :: [{:delay_secs, integer}]

    @spec async_delete(integer, integer, async_delete_opts) :: Honeydew.Job.t() | no_return
    def async_delete(chat_id, message_id, opts \\ []) do
      delay_secs = Keyword.get(opts, :delay_secs, 0)

      fun = {:delete, [chat_id, message_id]}

      Honeydew.async(fun, @queue_name, delay_secs: delay_secs)
    end

    def init_queue do
      :ok = Honeydew.start_queue(@queue_name, failure_mode: @failure_mode)
      :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
    end
  end

  defmodule ValidationTerminator do
    @moduledoc false

    @queue_name :validation_terminator
    @max_concurrency 9999

    @spec terminate(integer, integer, integer) :: :ok
    def terminate(chat_id, user_id, waiting_secs) do
      Logger.debug(
        "Validation validity time is about to end, start processing timeout, details: #{inspect(chat_id: chat_id, user_id: user_id, waiting_secs: waiting_secs)}"
      )

      Logger.debug("Timeout processing has ended")

      :ok
    end

    @spec async_terminate(integer, integer, integer) :: Honeydew.Job.t()
    def async_terminate(chat_id, user_id, waiting_secs) do
      fun = {:terminate, [chat_id, user_id, waiting_secs]}

      Honeydew.async(fun, @queue_name, delay_secs: waiting_secs)
    end

    def init_queue do
      :ok = Honeydew.start_queue(@queue_name)
      :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
    end
  end

  @doc """
  异步删除消息。

  删除请求失败会自动重试，最多重试三次。

  ## 可选参数
    - `delay_secs`: 延迟删除的秒数。
  """
  defdelegate async_delete_message(chat_id, message_id, opts \\ []),
    to: __MODULE__.MessageCleaner,
    as: :async_delete

  @doc """
  异步终止验证。

  通过 `waiting_secs` 强制延迟执行，延迟秒数即验证倒计时的时间。

  ## 提前结束任务
    当用户主动选择了验证答案后，任务应取消执行，因为超时情况已不存在。通过此函数的 `Honeydew.Job.t` 返回值，调用 `Honeydew.cancel/1` 即可取消。
  """
  defdelegate async_terminate_validation(chat_id, user_id, waiting_secs),
    to: __MODULE__.ValidationTerminator,
    as: :async_terminate
end
