defmodule PolicrMiniWeb.ConsoleV2.ViewHelper do
  @moduledoc false

  def success(payload) do
    %{
      success: true,
      payload: payload
    }
  end

  def success do
    %{
      success: true
    }
  end

  def failure(message) do
    %{
      success: false,
      message: message
    }
  end
end
