defmodule PolicrMini.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import PolicrMini.Schema
      import Ecto.Changeset

      alias PolicrMini.Repo

      @timestamps_opts [type: :utc_datetime]
    end
  end
end
