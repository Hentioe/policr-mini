defmodule PolicrMini.Bot.Commander do
  defmacro __using__(command) when is_atom(command) do
    quote do
      alias PolicrMini.Bot.{Commander, Cleaner}
      alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

      import Commander
      import PolicrMini.Bot.Helper

      @behaviour Commander
      @command "/#{Atom.to_string(unquote(command))}"

      @impl true
      def handle(message, state), do: {:ok, state}
      @impl true
      def match?(text), do: text == @command || text == "#{@command}@#{bot_username()}"

      defoverridable handle: 2
      defoverridable match?: 1
    end
  end

  @callback handle(message :: Telegex.Model.Message.t(), state :: PolicrMini.Bot.State.t()) ::
              {:ok | :ignored | :error, PolicrMini.Bot.State.t()}
  @callback match?(text :: binary()) :: boolean()
end
