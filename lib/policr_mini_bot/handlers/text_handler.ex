defmodule PolicrMiniBot.TextHandler do
  @moduledoc """
  文字消息的处理器。
  """

  use PolicrMiniBot.Handler

  @impl true
  def match?(message, state), do: {message.text != nil, state}

  @impl true
  def handle(_message, state) do
    {:ok, %{state | done: true}}
  end
end
