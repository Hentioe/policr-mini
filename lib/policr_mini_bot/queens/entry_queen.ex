defmodule PolicrMiniBot.EntryQueen do
  @moduledoc false

  use Honeycomb.Queen, id: :entry, concurrency: 99
end
