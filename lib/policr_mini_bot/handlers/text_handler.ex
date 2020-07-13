defmodule PolicrMiniBot.TextHandler do
  use PolicrMiniBot.Handler

  @impl true
  def match?(message, state), do: {message.text != nil, state}

  @impl true
  def handle(_message, state) do
    {:ok, %{state | done: true}}
  end
end
