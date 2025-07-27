defmodule PolicrMiniWeb.ConsoleV2.Helpers do
  @moduledoc false

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def controller do
    quote do
      import PolicrMiniWeb.ConsoleV2.ControllerHelper
    end
  end

  def view do
    quote do
      import PolicrMiniWeb.ConsoleV2.ViewHelper
    end
  end
end
