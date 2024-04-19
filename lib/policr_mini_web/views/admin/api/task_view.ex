defmodule PolicrMiniWeb.Admin.API.TaskView do
  use PolicrMiniWeb, :view

  @spec render(String.t(), map()) :: map()
  def render("index.json", %{jobs: jobs}) do
    %{
      jobs: render_many(jobs, __MODULE__, "job.json")
    }
  end

  def render("job.json", %{task: task}) do
    task |> Map.from_struct()
  end

  def render("result.json", %{ok: ok}) do
    %{ok: ok}
  end
end
