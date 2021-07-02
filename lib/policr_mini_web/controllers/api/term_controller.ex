defmodule PolicrMiniWeb.API.TermController do
  @moduledoc """
  服务条款的前台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.Instance

  action_fallback PolicrMiniWeb.API.FallbackController

  def index(conn, _params) do
    with {:ok, term} <- Instance.fetch_term(),
         {:ok, html_content} <- as_html(term.content) do
      render(conn, "index.json", %{term: term, html_content: html_content})
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
