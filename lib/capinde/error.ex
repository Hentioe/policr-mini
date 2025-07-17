defmodule Capinde.Error do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field :message, String.t(), enforce: true
    field :code, integer()
  end
end
