defmodule PolicrMini.Bot.State do
  @moduledoc """
  在过滤器中传递的状态。
  """

  use TypedStruct

  typedstruct do
    field :takeovered, boolean()
    field :from_self, boolean()
    field :from_admin, boolean()
    field :deleted, boolean()
    field :done, boolean()
  end
end
