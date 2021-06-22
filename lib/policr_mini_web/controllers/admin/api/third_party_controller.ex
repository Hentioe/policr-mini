defmodule PolicrMiniWeb.Admin.API.ThirdPartyController do
  @moduledoc """
  第三方实例的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.ThirdPartyBusiness

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      third_parties = ThirdPartyBusiness.find_list()

      render(conn, "index.json", %{third_parties: third_parties})
    end
  end

  def add(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, third_party} <- ThirdPartyBusiness.create(params) do
      render(conn, "third_party.json", %{third_party: third_party})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, third_party} <- ThirdPartyBusiness.get(id),
         {:ok, third_party} <- ThirdPartyBusiness.update(third_party, params) do
      render(conn, "third_party.json", %{third_party: third_party})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, third_party} <- ThirdPartyBusiness.get(id),
         {:ok, third_party} <- ThirdPartyBusiness.delete(third_party) do
      render(conn, "third_party.json", %{third_party: third_party})
    end
  end
end
