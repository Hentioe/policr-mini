defmodule PolicrMiniBot.Worker do
  @moduledoc false

  # TODO: 持久化任务缓存。

  defmodule Error do
    defexception [:message]
  end

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      alias unquote(__MODULE__).Error
    end
  end

  @callback init_queue :: :ok

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
