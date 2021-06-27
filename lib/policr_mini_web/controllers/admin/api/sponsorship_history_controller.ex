defmodule PolicrMiniWeb.Admin.API.SponsorshipHistoryController do
  @moduledoc """
  赞助历史的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.{SponsorBusiness, SponsorshipHistoryBusiness}

  action_fallback PolicrMiniWeb.API.FallbackController

  @order_by [asc_nulls_first: :has_reached, desc: :reached_at, desc: :updated_at]
  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn) do
      sponsorship_histories =
        SponsorshipHistoryBusiness.find_list(preload: [:sponsor], order_by: @order_by)

      sponsors = SponsorBusiness.find_list()

      render(conn, "index.json", %{
        sponsorship_histories: sponsorship_histories,
        sponsors: sponsors
      })
    end
  end

  def add(conn, %{"sponsor" => sponsor} = params) when sponsor != nil do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_history} <-
           SponsorshipHistoryBusiness.create_with_sponsor(params) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end

  def add(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_history} <-
           SponsorshipHistoryBusiness.create(params) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end

  def update(conn, %{"id" => id, "sponsor" => sponsor} = params) when sponsor != nil do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_history} <- SponsorshipHistoryBusiness.get(id),
         {:ok, sponsorship_history} <-
           SponsorshipHistoryBusiness.update_with_create_sponsor(sponsorship_history, params) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_history} <- SponsorshipHistoryBusiness.get(id),
         {:ok, sponsorship_history} <-
           SponsorshipHistoryBusiness.update(sponsorship_history, params) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, sponsorship_history} <- SponsorshipHistoryBusiness.get(id),
         {:ok, sponsorship_history} <- SponsorshipHistoryBusiness.delete(sponsorship_history) do
      render(conn, "sponsorship_history.json", %{sponsorship_history: sponsorship_history})
    end
  end
end
