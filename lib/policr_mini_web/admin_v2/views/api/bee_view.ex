defmodule PolicrMiniWeb.AdminV2.API.BeeView do
  use PolicrMiniWeb, :admin_v2_view

  alias Honeycomb.Bee

  def render("show.json", %{bee: bee}) do
    success(render_one(bee, __MODULE__, "bee.json"))
  end

  def render("bee.json", %{bee: bee}) when is_struct(bee, Bee) do
    %{
      id: bee.name,
      status: bee.status,
      created_at: bee.create_at,
      expected_run_at: bee.expect_run_at,
      work_started_at: bee.work_start_at,
      work_ended_at: bee.work_end_at,
      result: render_result(bee.result)
    }
  end

  def render_result(result) when is_struct(result) do
    Map.from_struct(result)
  end

  def render_result(result), do: result
end
