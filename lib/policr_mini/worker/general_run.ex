defmodule PolicrMini.Worker.GeneralRun do
  @moduledoc false

  @queue_name :general_run

  def init_queue do
    :ok = Honeydew.start_queue(@queue_name)
    :ok = Honeydew.start_workers(@queue_name, __MODULE__)
  end

  def run(fun) do
    fun.()
  end

  def async_run(fun, opts \\ []) do
    delay_secs = Keyword.get(opts, :delay_secs, 0)

    fun = {:run, [fun]}

    Honeydew.async(fun, @queue_name, delay_secs: delay_secs)
  end
end
