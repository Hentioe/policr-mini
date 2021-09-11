defmodule PolicrMini.Schema do
  @moduledoc false

  @type params :: %{optional(atom) => any} | %{optional(String.t()) => any}

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import PolicrMini.Schema
      import Ecto.Changeset

      alias PolicrMini.Repo

      @timestamps_opts [type: :utc_datetime]

      %{context_modules: [module]} = __ENV__

      @schema_module module

      @type t :: Ecto.Schema.t()
      @type get_otps :: [{:preload, [atom]}]

      @spec get(any, get_otps) ::
              {:ok, Ecto.Schema.t()} | {:error, :not_found, %{params: map}}
      def get(id, options \\ []) do
        preload = Keyword.get(options, :preload, [])

        data =
          @schema_module
          |> Repo.get(id)
          |> Repo.preload(preload)

        case data do
          nil -> {:error, :not_found, %{params: %{schema: @schema_module, id: id}}}
          r -> {:ok, r}
        end
      end
    end
  end
end
