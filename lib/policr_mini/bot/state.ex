defmodule PolicrMini.Bot.State do
  defstruct [:takeovered, :from_self, :from_admin, :deleted, :done]

  @type t :: %__MODULE__{
          takeovered: boolean(),
          from_self: boolean(),
          from_admin: boolean(),
          deleted: boolean(),
          done: boolean()
        }
end
