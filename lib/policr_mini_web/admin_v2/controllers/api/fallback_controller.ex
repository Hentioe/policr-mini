defmodule PolicrMiniWeb.AdminV2.API.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, %Capinde.Error{message: message}}) do
    conn
    |> put_view(PolicrMiniWeb.AdminV2.API.ErrorView)
    |> render("error.json", %{message: message})
  end

  def call(conn, {:error, %Telegex.Error{description: description}}) do
    conn
    |> put_view(PolicrMiniWeb.AdminV2.API.ErrorView)
    |> render("error.json", %{message: description})
  end

  def call(conn, {:error, %{range: ["not be in the inclusion list"]}}) do
    conn
    |> put_view(PolicrMiniWeb.AdminV2.API.ErrorView)
    |> render("error.json", %{message: "无效的范围参数"})
  end
end
