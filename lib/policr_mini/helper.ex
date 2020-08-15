defmodule PolicrMini.Helper do
  @moduledoc false

  alias :mnesia, as: Mnesia

  @spec init_mnesia! :: [atom]
  def init_mnesia! do
    node_list = [node()]

    Mnesia.create_schema(node_list)

    case Mnesia.start() do
      :ok ->
        node_list

      {:error, {:nonode@nohost, {:already_exists, :nonode@nohost}}} ->
        node_list

      e ->
        raise inspect(e)
    end
  end

  @spec check_mnesia_created_table!([tuple] | tuple) :: :ok
  def check_mnesia_created_table!(table_results) when is_list(table_results) do
    failure_finder = fn result ->
      case result do
        {:atomic, :ok} ->
          false

        {:aborted, {:already_exists, _}} ->
          false

        _ ->
          true
      end
    end

    failed_result = Enum.find(table_results, failure_finder)

    if failed_result, do: raise(inspect(failed_result))

    :ok
  end

  def check_mnesia_created_table!(table_result) when is_tuple(table_result),
    do: check_mnesia_created_table!([table_result])
end
