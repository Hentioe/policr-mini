defmodule PolicrMiniWeb.ConsoleV2.API.FallbackController do
  use Phoenix.Controller

  def call(conn, {:write, false}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "无权操作此资源"})
  end

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

  def call(conn, {:error, %{limit: [<<"must be less than or equal to " <> limit>>]}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "页面大小不可超过 #{limit}"})
  end

  def call(conn, {:error, %{action: ["not be in the inclusion list"]}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "无效的操作类型"})
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

  def call(conn, {:error, %Ecto.Changeset{errors: [answers: {"incorrect format", []}]}}) do
    conn
    |> put_view(PolicrMiniWeb.ConsoleV2.API.ErrorView)
    |> render("error.json", %{message: "包含错误的答案格式"})
  end
end
