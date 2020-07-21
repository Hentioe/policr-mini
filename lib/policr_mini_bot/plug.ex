defmodule PolicrMiniBot.Plug do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      import PolicrMiniBot.Helper

      if is_list(unquote(opts)) && Enum.empty?(unquote(opts)) do
        use Telegex.Plug
      else
        use Telegex.Plug.Preset, unquote(opts)
      end
    end
  end
end
