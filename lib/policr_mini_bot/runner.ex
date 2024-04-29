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
      field :timezone, String.t()
    end

    def from({name, job}) when is_atom(name) and is_struct(job, Quantum.Job) do
      %__MODULE__{
        name: name,
        next_run_datetime: Crontab.Scheduler.get_next_run_date!(job.schedule),
        timezone: job.timezone |> Atom.to_string() |> String.upcase()
      }
      |> put_texts()
    end

    @spec put_texts(map) :: map
    def put_texts(%{name: :expired_check} = job) do
      %{job | name_text: "过期验证检查", schedule_text: "每 5 分钟"}
    end

    def put_texts(%{name: :working_check} = job) do
      %{job | name_text: "工作状态检查", schedule_text: "每 4 小时"}
    end

    def put_texts(%{name: :left_check} = job) do
      %{job | name_text: "退出检查", schedule_text: "每日"}
    end

    def put_texts(%{name: :third_parties_running_days_update} = job) do
      %{job | name_text: "第三方实例运行天数更新", schedule_text: "每日"}
    end

    def put_texts(%{name: name} = job) do
      %{job | name_text: name}
    end
  end

  @spec jobs() :: [Job.t()]
  def jobs do
    quantom_jobs = PolicrMiniBot.Scheduler.jobs()

    Enum.map(quantom_jobs, &Job.from/1)
  end
end
