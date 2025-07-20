defmodule PolicrMiniWeb.AdminV2.API.ProviderController do
  use PolicrMiniWeb, :controller

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def upload(conn, %{"archive" => %{content_type: content_type} = archive} = _params)
      when content_type == "application/zip" do
    with {:ok, archive_info} <- Capinde.upload(archive.path) do
      render(conn, "uploaded.json", %{archive_info: archive_info})
    end
  end

  def upload(conn, %{"archive" => %{content_type: _content_type}} = _params) do
    render(conn, "failure.json", %{message: "only zip files are allowed"})
  end
end
