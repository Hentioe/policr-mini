defmodule PolicrMiniBot.Worker.ValidationTerminator do
  @moduledoc """
  负责终止验证（处理超时）的 Worker。
  """

  use PolicrMiniBot.Worker

  alias PolicrMini.Logger

  @queue_name :validation_terminator
  @max_concurrency 9999

  @impl true
  def init_queue do
    :ok = Honeydew.start_queue(@queue_name)
    :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
  end

  @impl true
  def job_key(:terminate, [chat_id, user_id, _]) do
    "terminate-#{chat_id}-#{user_id}"
  end

  @spec terminate(integer, integer, integer) :: :ok
  def terminate(chat_id, user_id, waiting_secs) do
    Logger.debug(
      "Validation validity time is about to end, start processing timeout, details: #{inspect(chat_id: chat_id, user_id: user_id, waiting_secs: waiting_secs)}"
    )

    Logger.debug("Timeout processing has ended")

    # 从缓存中删除任务
    JobCacher.delete_job(job_key(:terminate, [chat_id, user_id, waiting_secs]))

    :ok
  end

  @spec async_terminate(integer, integer, integer) :: Honeydew.Job.t()
  def async_terminate(chat_id, user_id, waiting_secs) do
    job_key = job_key(:terminate, [chat_id, user_id, waiting_secs])

    if job = JobCacher.get_job(job_key) do
      # 已存在，取消任务
      Logger.debug(
        "Termination verification task already exists, cancel execution, details: #{inspect(chat_id: chat_id, user_id: user_id)}"
      )

      Honeydew.cancel(job)
    end

    fun = {:terminate, [chat_id, user_id, waiting_secs]}

    job = Honeydew.async(fun, @queue_name, delay_secs: waiting_secs)

    JobCacher.add_job(job_key, job)

    job
  end
end
