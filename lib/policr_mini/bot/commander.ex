defmodule PolicrMini.Bot.Commander do
  defmacro __using__(_) do
    quote do
      alias PolicrMini.Bot.Commander
      import Commander

      @behaviour Commander

      @impl true
      def handle(message, state), do: {:ok, state}

      defoverridable handle: 2
    end
  end

  defmacro command(name) do
    command_text = "/#{Atom.to_string(name)}"

    quote do
      def command, do: unquote(command_text)
    end
  end

  @callback handle(message :: Nadia.Model.Message.t(), state :: PolicrMini.Bot.State.t()) ::
              {:ok | :ignored, PolicrMini.Bot.State.t()}
end
