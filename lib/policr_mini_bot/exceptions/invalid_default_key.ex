defmodule PolicrMiniBot.Exceptions.InvalidDefaultKey do
  @moduledoc false

  defexception [:message]

  def exception(key) do
    %__MODULE__{message: "Invalid default key: #{inspect(key)}"}
  end
end
