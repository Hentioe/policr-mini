defmodule PolicrMini.I18n do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import PolicrMiniWeb.Gettext
      import unquote(__MODULE__)

      require unquote(__MODULE__)
    end
  end

  defmacro commands_text(msg_id, bindings \\ []) do
    msg_id =
      if is_binary(msg_id) do
        String.trim(msg_id)
      else
        msg_id
      end

    quote do
      dgettext("commands", unquote(msg_id), unquote(bindings))
    end
  end
end
