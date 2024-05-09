defmodule PolicrMiniBot.Worker do
  @moduledoc false

  # TODO: 持久化任务缓存。

  require Logger

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
  @callback job_key(task :: atom, args :: any) :: any

  @doc """
  异步终止验证。

  通过 `waiting_secs` 强制延迟执行，延迟秒数即验证倒计时的时间。

  ## 提前结束任务
    当用户主动选择了验证答案后，任务应取消执行，因为超时情况已不存在。通过此函数的 `Honeydew.Job.t` 返回值，调用
    `PolicrMiniBot.Worker.cancel_terminate_validation_job/2` 即可取消。
  """
  defdelegate async_terminate_validation(veri, scheme, waiting_secs),
    to: __MODULE__.VerificationTerminator,
    as: :async_terminate

  @doc """
  手动终止验证。

  手动终止验证会取消超时处理任务，并更新验证入口消息。若验证的状态不是 `waiting` 则忽略处理。
  """
  defdelegate manual_terminate_validation(veri, status),
    to: __MODULE__.VerificationTerminator,
    as: :manual_terminate

  def cancel_terminate_validation_job(chat_id, user_id) do
    key = __MODULE__.VerificationTerminator.job_key(:terminate, [chat_id, user_id])

    if job = JobCacher.pop_job(key) do
      case Honeydew.cancel(job) do
        :ok ->
          Logger.debug(
            "Termination of verification job has been canceled: #{inspect(chat_id: chat_id, user_id: user_id)}"
          )

        _ ->
          :ignored
      end
    end

    :ok
  end
end
