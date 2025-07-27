defmodule PolicrMini.Plausible do
  @moduledoc false

  # 是否集成
  def integrated do
    domain() && script_src()
  end

  def domain do
    config_get(:domain)
  end

  def script_src do
    config_get(:script_src)
  end

  def config_get(key, default \\ nil) do
    Application.get_env(:policr_mini, __MODULE__)[key] || default
  end
end
