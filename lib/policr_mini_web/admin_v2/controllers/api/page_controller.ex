defmodule PolicrMiniWeb.AdminV2.API.PageController do
  use PolicrMiniWeb, :controller

  def assets(conn, _params) do
    deployed =
      case Capinde.deployed() do
        {:ok, deployed} -> deployed
        _ -> nil
      end

    uploaded =
      case Capinde.uploaded() do
        {:ok, uploaded} -> uploaded
        _ -> nil
      end

    render(conn, "assets.json", deployed: deployed, uploaded: uploaded)
  end
end
