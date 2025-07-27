defmodule PolicrMiniWeb.ConsoleV2.ControllerHelper do
  @moduledoc false

  alias PolicrMiniWeb.AdminV2.ViewHelper

  def resp_forbidden(conn) do
    conn
    |> Plug.Conn.put_status(:forbidden)
    |> Phoenix.Controller.json(JSON.encode!(ViewHelper.failure("Forbidden")))
    |> Plug.Conn.halt()
  end
end
