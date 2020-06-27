defmodule PolicrMini.Bot.Callbacker do
  defmacro __using__(prefix) when is_atom(prefix) do
    quote do
      alias PolicrMini.Bot.{Callbacker, Cleaner}
      alias Telegex.Model.{InlineKeyboardMarkup, InlineKeyboardButton}

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

  @callback handle(callback_query :: Telegex.Model.CallbackQuery.t()) ::
              :ok | :ignored | :error
  @callback match?(data :: String.t()) :: boolean()

  @spec answer_callback_query(String.t(), keyword()) :: :ok | {:error, Telegex.Model.errors()}
  @doc """
  响应回调查询。
  """
  def answer_callback_query(callback_query_id, options \\ []) do
    Telegex.answer_callback_query(callback_query_id, options)
  end

  @spec parse_callback_data(String.t()) :: {String.t(), [String.t()]}
  @doc """
  解析回调中的数据。
  """
  def parse_callback_data(data) when is_binary(data) do
    [_, version | args] = data |> String.split(":")

    {version, args}
  end
end
