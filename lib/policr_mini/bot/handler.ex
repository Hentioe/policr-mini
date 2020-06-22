defmodule PolicrMini.Bot.Handler do
  alias PolicrMini.Bot.State

  defmacro __using__(_) do
    quote do
      alias PolicrMini.Bot.{Handler, State, Cleaner}
      alias Nadia.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

      import Handler
      import PolicrMini.Bot.Helper

      @behaviour Handler

      @impl true
      def match?(message, state), do: {false, state}
      @impl true
      def handle(message, state), do: {:ok, state}

      defoverridable match?: 2
      defoverridable handle: 2
    end
  end

  @callback match?(msg :: Nadia.Model.Message.t(), state :: State.t()) ::
              {boolean(), State.t()}
  @callback handle(msg :: Nadia.Model.Message.t(), state :: State.t()) ::
              {:ok | :ignored | :error, State.t()}
end
