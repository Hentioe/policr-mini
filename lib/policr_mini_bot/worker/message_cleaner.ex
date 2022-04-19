defmodule PolicrMiniBot.Worker.MessageCleaner do
  @moduledoc false

  use PolicrMiniBot.Worker

  alias PolicrMini.Logger

  @queue_name :message_cleaner
  @failure_mode {Honeydew.FailureMode.Retry, times: 5}
  @max_concurrency 50

  @impl true
  def init_queue do
    :ok = Honeydew.start_queue(@queue_name, failure_mode: @failure_mode)
    :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
  end

  def delete(chat_id, message_id) do
    case Telegex.delete_message(chat_id, message_id) do
      {:error, %Telegex.Model.RequestError{reason: reason}} ->
        raise Error,
          message: "Failed to send delete message request, reason: #{reason}"

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
end
