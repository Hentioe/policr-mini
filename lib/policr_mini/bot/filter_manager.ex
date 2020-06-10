defmodule PolicrMini.Bot.FilterManager do
  use Agent

  def start_link(opts) do
    commanders = Keyword.get(opts, :commanders, [])
    handlers = Keyword.get(opts, :handlers, [])
    filters = [commanders: commanders, handlers: handlers]
    Agent.start_link(fn -> filters end, name: __MODULE__)
  end

  defp get(key) do
    Agent.get(__MODULE__, fn filters -> Keyword.get(filters, key, []) end)
  end

  def commanders, do: get(:commanders)
  def handlers, do: get(:handlers)
end
