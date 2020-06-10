defmodule PolicrMini.Bot.TextHandler do
  use PolicrMini.Bot.Handler

  @impl true
  def match?(message, state), do: {message.text != nil, state}

  @impl true
  def handle(_message, state) do
    {:ok, %{state | done: true}}
  end
end
