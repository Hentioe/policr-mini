defmodule PolicrMiniWeb.Admin.API.ProfileView do
  @moduledoc """
  渲染后台全局属性数据。
  """

  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{scheme: scheme}) do
    scheme = render_one(scheme, PolicrMiniWeb.Admin.API.SchemeView, "scheme.json")

    %{
      scheme: scheme
    }
  end

  def render("result.json", %{ok: ok}) do
    %{
      ok: ok
    }
  end
end
