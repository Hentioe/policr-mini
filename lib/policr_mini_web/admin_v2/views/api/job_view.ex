defmodule PolicrMiniWeb.AdminV2.API.JobView do
  use PolicrMiniWeb, :admin_v2_view

  alias PolicrMiniBot.Runner.Job

  def render("job.json", %{job: job}) when is_struct(job, Job) do
    %{
      id: job.name,
      name: job.name_text,
      period: job.schedule_text,
      scheduled: true,
      next_run_at: job.next_run_datetime
    }
  end
end
