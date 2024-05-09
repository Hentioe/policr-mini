defmodule PolicrMini.BackgroundQueen do
  @moduledoc false

  use Honeycomb.Queen, id: :background, concurrency: 1
end
