defmodule PolicrMiniWeb.Admin.API.LogView do
  @moduledoc """
  渲染后台日志数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{logs: logs, level: level, beginning: beginning, ending: ending}) do
    %{
      logs: render_many(logs, __MODULE__, "log.json"),
      level: level,
      beginning: beginning,
      ending: ending
    }
  end

  def render("log.json", %{log: log}) do
    Map.from_struct(log)
  end
end
