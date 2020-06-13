defmodule PolicrMini.Bot.Callbacker do
  defmacro __using__(prefix) when is_atom(prefix) do
    quote do
      alias PolicrMini.Bot.Callbacker
      alias Nadia.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

      import Callbacker
      import PolicrMini.Bot.Helper

      @behaviour Callbacker
      @prefix Atom.to_string(unquote(prefix))

      @impl true
      def handle(callback_query), do: :ok
      @impl true
      def match?(data), do: data |> String.split(":") |> hd == @prefix

      defoverridable handle: 1
      defoverridable match?: 1
    end
  end

  @callback handle(callback_query :: Nadia.Model.CallbackQuery.t()) ::
              :ok | :ignored | :error
  @callback match?(data :: String.t()) :: boolean()
end
