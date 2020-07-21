defmodule PolicrMiniBot.State do
  @moduledoc """
  在过滤器中传递的状态。
  """

  use TypedStruct

  typedstruct do
    field :takeovered, boolean()
    field :from_self, boolean()
    field :from_admin, boolean()
    field :deleted, boolean(), default: false
    field :done, boolean(), default: false
  end
end
