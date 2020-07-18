defmodule PolicrMiniBot.Handler do
  @moduledoc """
  通用处理器。
  """

  alias PolicrMiniBot.State

  defmacro __using__(_) do
    quote do
      alias PolicrMiniBot.{Handler, State, Cleaner}
      alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

      import Handler
      import PolicrMiniBot.Helper

      @behaviour Handler

      @impl true
      def match?(message, state), do: {false, state}
      @impl true
      def handle(message, state), do: {:ok, state}

      defoverridable match?: 2
      defoverridable handle: 2
    end
  end

  @callback match?(msg :: Telegex.Model.Message.t(), state :: State.t()) ::
              {boolean(), State.t()}
  @callback handle(msg :: Telegex.Model.Message.t(), state :: State.t()) ::
              {:ok | :ignored | :error, State.t()}
end
