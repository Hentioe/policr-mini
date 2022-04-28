defmodule PolicrMiniBot.Runner do
  @moduledoc """
  定时任务功能。
  """

  defmodule Job do
    @moduledoc false

    use TypedStruct

    typedstruct do
      field :name, String.t()
      field :name_text, String.t()
      field :schedule_text, String.t()
      field :next_run_datetime, NaiveDateTime.t()
      field :timezone, String
    end

    def from({name, job}) when is_atom(name) and is_struct(job, Quantum.Job) do
      %__MODULE__{
        name: name,
        next_run_datetime: Crontab.Scheduler.get_next_run_date!(job.schedule),
        timezone: job.timezone |> Atom.to_string() |> String.upcase()
      }
      |> put_text()
    end

    @spec put_text(map) :: map
    def put_text(%{name: :expired_check} = job) do
      %{job | name_text: "过期验证检查", schedule_text: "每 5 分钟"}
    end

    def put_text(%{name: :working_check} = job) do
      %{job | name_text: "工作状态检查", schedule_text: "每 55 分钟"}
    end

    def put_text(%{name: :left_check} = job) do
      %{job | name_text: "退出检查", schedule_text: "每日"}
    end
  end

  @spec jobs() :: [Job.t()]
  def jobs do
    quantom_jobs = PolicrMiniBot.Scheduler.jobs()

    Enum.map(quantom_jobs, &Job.from/1)
  end
end
