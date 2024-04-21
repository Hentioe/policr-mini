defmodule PolicrMiniWeb.Admin.API.TaskView do
  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{scheduled_jobs: scheduled_jobs, stateful_jobs: stateful_jobs}) do
    %{
      scheduled_jobs: render_many(scheduled_jobs, __MODULE__, "scheduled_job.json"),
      stateful_jobs: stateful_jobs
    }
  end

  def render("scheduled_job.json", %{task: task}) do
    Map.from_struct(task)
  end

  def render("result.json", %{ok: ok}) do
    %{ok: ok}
  end
end
