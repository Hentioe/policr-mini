defmodule PolicrMiniWeb.AdminV2.API.ProviderController do
  use PolicrMiniWeb, :controller

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  import PolicrMiniWeb.AdminV2.ViewHelper

  def upload(conn, %{"archive" => %{content_type: content_type} = archive} = _params)
      when content_type == "application/zip" do
    with {:ok, archive_info} <- Capinde.upload(archive.path) do
      render(conn, "uploaded.json", %{archive_info: archive_info})
    end
  end

  def upload(conn, %{"archive" => %{content_type: _content_type}} = _params) do
    json(conn, failure("only zip files are allowed"))
  end

  def delete(conn, _params) do
    with {:ok, _} <- Capinde.delete_uploaded() do
      json(conn, success())
    end
  end

  def deploy(conn, _parms) do
    with {:ok, _} <- Capinde.deploy_uploaded() do
      json(conn, success())
    end
  end
end
