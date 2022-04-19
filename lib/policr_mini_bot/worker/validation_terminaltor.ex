defmodule PolicrMiniBot.Worker.ValidationTerminator do
  @moduledoc false

  use PolicrMiniBot.Worker

  alias PolicrMini.Logger

  @queue_name :validation_terminator
  @max_concurrency 9999

  @impl true
  def init_queue do
    :ok = Honeydew.start_queue(@queue_name)
    :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
  end

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
end
