defmodule PolicrMiniWeb.Admin.API.SponsorshipAddressController do
  @moduledoc """
  赞助地址的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.Instances
  alias PolicrMini.Instances.SponsorshipAddress

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      sponsorship_addresses = Instances.find_sponsorship_addresses()

      render(conn, "index.json", %{sponsorship_addresses: sponsorship_addresses})
    end
  end

  def add(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_addresses} <- Instances.create_sponsorship_address(params) do
      render(conn, "sponsorship_addresses.json", %{sponsorship_addresses: sponsorship_addresses})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_addresses} <- SponsorshipAddress.get(id),
         {:ok, sponsorship_addresses} <-
           Instances.update_sponsorship_address(sponsorship_addresses, params) do
      render(conn, "sponsorship_addresses.json", %{sponsorship_addresses: sponsorship_addresses})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_addresses} <- SponsorshipAddress.get(id),
         {:ok, sponsorship_addresses} <-
           Instances.delete_sponsorship_address(sponsorship_addresses) do
      render(conn, "sponsorship_addresses.json", %{sponsorship_addresses: sponsorship_addresses})
    end
  end
end
