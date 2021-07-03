defmodule PolicrMiniWeb.Admin.API.TermController do
  @moduledoc """
  服务条款的后台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  import PolicrMiniWeb.Helper

  alias PolicrMini.Instances

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, term} <- Instances.fetch_term() do
      render(conn, "index.json", %{term: term})
    end
  end

  def add_or_update(conn, params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, term} <- Instances.fetch_term(),
         {:ok, term} <- Instances.update_term(term, params) do
      render(conn, "term.json", %{term: term})
    end
  end

  def delete(conn, _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, term} <- Instances.fetch_term(),
         {:ok, term} <- Instances.delete_term(term) do
      render(conn, "term.json", %{term: term})
    end
  end

  def preview(conn, %{"content" => content} = _params) do
    with {:ok, _} <- check_sys_permissions(conn),
         {:ok, html} <- as_html(content) do
      render(conn, "preview.json", %{html: html})
    end
  end

  defp as_html(nil) do
    {:ok, ""}
  end

  defp as_html(text) do
    case Earmark.as_html(text) do
      {:ok, html_doc, _} -> {:ok, html_doc}
      {:error, _html_doc, error_messages} -> {:error, %{descriptin: error_messages}}
    end
  end
end
