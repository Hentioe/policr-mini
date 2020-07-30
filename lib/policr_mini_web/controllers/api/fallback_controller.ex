defmodule PolicrMiniWeb.API.FallbackController do
  @moduledoc """
  API 相关的后备控制器，用于响应错误。

  注意：当前此后备控制器被前后台 API 控制器共用。
  """

  use Phoenix.Controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_view(PolicrMiniWeb.API.ErrorView)
    |> render("error.json", %{changeset: changeset})
  end

  def call(conn, {:error, %{description: description}}) do
    conn
    |> put_view(PolicrMiniWeb.API.ErrorView)
    |> render("error.json", %{description: description})
  end

  def call(conn, {:error, :not_found, info}) do
    conn
    |> put_view(PolicrMiniWeb.API.ErrorView)
    |> render("error.json", %{not_found: info})
  end
end
