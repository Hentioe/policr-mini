defmodule PolicrMiniWeb.Admin.API.ThirdPartyController do
  @moduledoc """
  第三方实例的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.Instances
  alias PolicrMini.Instances.ThirdParty

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      third_parties = Instances.find_third_parties()

      render(conn, "index.json", %{third_parties: third_parties})
    end
  end

  def add(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, third_party} <- Instances.create_third_party(params) do
      render(conn, "third_party.json", %{third_party: third_party})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, third_party} <- ThirdParty.get(id),
         {:ok, third_party} <- Instances.update_third_party(third_party, params) do
      render(conn, "third_party.json", %{third_party: third_party})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, third_party} <- ThirdParty.get(id),
         {:ok, third_party} <- Instances.delete_third_party(third_party) do
      render(conn, "third_party.json", %{third_party: third_party})
    end
  end
end
