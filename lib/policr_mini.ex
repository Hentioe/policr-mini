defmodule PolicrMini do
  @moduledoc """
  PolicrMini keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defmacro __using__(business: schema_module) do
    quote do
      alias unquote(schema_module)
      alias PolicrMini.Repo

      def get(id, options \\ []) do
        preload = Keyword.get(options, :preload, [])
        record = unquote(schema_module) |> Repo.get(id) |> Repo.preload(preload)

        case record do
          nil -> {:error, :not_found, %{params: %{entry: unquote(schema_module), id: id}}}
          r -> {:ok, r}
        end
      end
    end
  end

  def mix_env, do: Application.get_env(:policr_mini, :environment)

  @official_bots ["policr_mini_bot", "policr_mini_test_bot"]
  def official_bots, do: @official_bots
end
