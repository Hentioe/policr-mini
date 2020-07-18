defmodule PolicrMini.Migration do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      use Ecto.Migration
    end
  end
end
