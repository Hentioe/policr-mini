defmodule PolicrMiniWeb.Admin.API.TaskView do
  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{scheduled_jobs: scheduled_jobs, bees: bees}) do
    %{
      scheduled_jobs: render_many(scheduled_jobs, __MODULE__, "scheduled_job.json"),
      stateful_jobs: Enum.map(bees, &bee/1)
    }
  end

  def render("scheduled_job.json", %{task: task}) do
    Map.from_struct(task)
  end

  def render("result.json", %{bee: bee}) do
    %{bee: bee(bee)}
  end

  defp bee(bee) do
    %{
      name: bee.name,
      status: bee.status,
      start_at: bee.work_start_at,
      end_at: bee.work_end_at,
      result: bee.result
    }
  end
end
