defmodule PolicrMini.Migration do
  defmacro __using__(_) do
    quote do
      use Ecto.Migration
    end
  end
end
