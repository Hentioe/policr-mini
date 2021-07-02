defmodule PolicrMini.Context do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @type params :: %{optional(atom) => any} | %{optional(String.t()) => any}
    end
  end
end
