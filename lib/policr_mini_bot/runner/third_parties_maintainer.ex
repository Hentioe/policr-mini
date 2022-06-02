defmodule PolicrMiniBot.Runner.ThirdPartiesMaintainer do
  @moduledoc false

  alias PolicrMini.Instances

  def add_job do
    import Crontab.CronExpression

    job_name = :third_parties_running_days_update

    PolicrMiniBot.Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(~e[@daily])
    |> Quantum.Job.set_task(&update_running_days/0)
    |> PolicrMiniBot.Scheduler.add_job()
  end

  def update_running_days do
    third_parties = Instances.find_third_parties()

    _ =
      third_parties
      |> Stream.map(&update_running_days/1)
      |> Enum.to_list()

    :ok
  end

  def update_running_days(third_party) do
    running_days = Date.diff(Date.utc_today(), third_party.inserted_at)

    params = %{running_days: running_days}

    Instances.update_third_party(third_party, params)
  end
end
