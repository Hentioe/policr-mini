defmodule PolicrMiniWeb.API.ErrorView do
  @moduledoc """
  显示错误数据的视图。

  注意：当前此错误视图被前后台 API 控制器共用。
  """

  use PolicrMiniWeb, :view

  def render("error.json", %{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)

    %{errors: errors}
  end

  def render("error.json", %{description: description}) do
    %{errors: %{description: [description]}}
  end

  def render("error.json", %{not_found: info}) do
    %{params: %{entry: entry}} = info

    entry = entry |> to_string() |> String.split(".") |> List.last() |> Macro.underscore()

    %{errors: %{entry => ["not found"]}}
  end
end
