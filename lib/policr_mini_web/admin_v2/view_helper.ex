defmodule PolicrMiniWeb.AdminV2.ViewHelper do
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
