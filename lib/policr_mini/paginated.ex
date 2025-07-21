defmodule PolicrMini.Paginated do
  @moduledoc false

  use TypedStruct

  typedstruct do
    field :page, non_neg_integer()
    field :page_size, non_neg_integer()
    field :items, [any()]
    field :total, non_neg_integer()
  end
end
