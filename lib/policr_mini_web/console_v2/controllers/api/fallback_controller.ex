defmodule PolicrMiniWeb.ConsoleV2.API.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, %Capinde.Error{message: message}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: message})
  end

  def call(conn, {:error, %Telegex.Error{description: description}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: description})
  end

  def call(conn, {:error, %{range: ["not be in the inclusion list"]}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "无效的范围参数"})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "未找到资源"})
  end

  def call(conn, {:error, %Ecto.Changeset{errors: [answers: {"missing correct answer", []}]}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "缺少正确答案"})
  end
end
