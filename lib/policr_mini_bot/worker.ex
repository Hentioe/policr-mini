defmodule PolicrMiniBot.Worker do
  @moduledoc false

  # TODO: 持久化任务缓存。

  alias PolicrMini.Logger

  defmodule JobCacher do
    @moduledoc false

    use Agent

    def start_link(_) do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    @spec add_job(any, Honeydew.Job.t()) :: :ok
    def add_job(key, job) when is_struct(job, Honeydew.Job) do
      Agent.update(__MODULE__, fn state -> Map.put(state, key, job) end)
    end

    @spec get_job(any) :: Honeydew.Job.t() | nil
    def get_job(key) do
      Agent.get(__MODULE__, fn state -> Map.get(state, key) end)
    end

    @spec pop_job(any) :: Honeydew.Job.t() | nil
    def pop_job(key) do
      Agent.get_and_update(__MODULE__, fn state -> Map.pop(state, key) end)
    end

    @spec delete_job(any) :: :ok
    def delete_job(key) do
      Agent.update(__MODULE__, fn state -> Map.delete(state, key) end)
    end
  end

  defmodule Error do
    defexception [:message]
  end

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      alias unquote(__MODULE__)
      alias unquote(__MODULE__).{Error, JobCacher}
    end
  end

  @callback init_queue :: :ok
  @callback job_key(task :: atom, args :: [any]) :: any

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

  def cancel_terminate_validation_job(chat_id, user_id) do
    # 此处的第三次参数不重要，不参与 key 的生成。
    key = __MODULE__.ValidationTerminator.job_key(:terminate, [chat_id, user_id, 0])

    if job = JobCacher.pop_job(key) do
      case Honeydew.cancel(job) do
        :ok ->
          Logger.debug(
            "Terminate verification task has been canceled, details: #{inspect(chat_id: chat_id, user_id: user_id)}"
          )

        _ ->
          :ignored
      end
    end

    :ok
  end
end
