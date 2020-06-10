defmodule PolicrMini.Bot.Handler do
  defmacro __using__(_) do
    quote do
      alias PolicrMini.Bot.Handler
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

  @callback match?(msg :: Nadia.Model.Message.t(), state :: PolicrMini.Bot.State.t()) ::
              {boolean(), PolicrMini.Bot.State.t()}
  @callback handle(msg :: Nadia.Model.Message.t(), state :: PolicrMini.Bot.State.t()) ::
              {:ok | :ignored, PolicrMini.Bot.State.t()}
end
