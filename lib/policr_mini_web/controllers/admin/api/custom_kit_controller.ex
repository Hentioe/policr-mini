defmodule PolicrMiniWeb.Admin.API.CustomKitController do
  @moduledoc """
  和 CustomKit 相关的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.CustomKitBusiness

  action_fallback PolicrMiniWeb.API.FallbackController

  def add(conn, params) do
    with {:ok, custom_kit} <- CustomKitBusiness.create(params) do
      render(conn, "custom_kit.json", %{custom_kit: custom_kit})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, custom_kit} <- CustomKitBusiness.get(id),
         {:ok, custom_kit} <- CustomKitBusiness.update(custom_kit, params) do
      render(conn, "custom_kit.json", %{custom_kit: custom_kit})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, custom_kit} <- CustomKitBusiness.get(id),
         {:ok, custom_kit} <- CustomKitBusiness.delete(custom_kit) do
      render(conn, "custom_kit.json", %{custom_kit: custom_kit})
    end
  end
end
