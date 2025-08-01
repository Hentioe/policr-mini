defmodule PolicrMiniBot.Worker.VerificationTerminator do
  @moduledoc """
  负责终止验证（处理超时）的 Worker。
  """

  use PolicrMiniBot.Worker

  alias PolicrMini.{Repo, Chats, Stats}
  alias PolicrMini.Chats.{Scheme, Verification}

  import PolicrMiniBot.{Helper, VerificationHelper}

  require Logger

  @queue_name :validation_terminator
  @max_concurrency 9999

  @impl true
  def init_queue do
    :ok = Honeydew.start_queue(@queue_name)
    :ok = Honeydew.start_workers(@queue_name, __MODULE__, num: @max_concurrency)
  end

  @impl true
  def job_key(:terminate = task, veri) when is_struct(veri, Verification) do
    %{chat_id: chat_id, target_user_id: user_id} = veri

    job_key(task, [chat_id, user_id])
  end

  @impl true
  def job_key(:terminate, [chat_id, user_id]) do
    "terminate-#{chat_id}-#{user_id}"
  end

  # TODO: 自定义失败模式，当失败发生时更新验证状态并移除任务缓存。
  @doc """
  终止超时验证。
  """
  @spec terminate(Verification.t(), Scheme.t(), integer) :: :ok
  def terminate(v, scheme, _waiting_secs)
      when is_struct(v, Verification) and is_struct(scheme, Scheme) do
    %{chat_id: chat_id, target_user_id: user_id} = v

    Logger.debug(
      "[#{v.id}] Verification timeout processing has started: #{inspect(chat_id: chat_id, user_id: user_id)}"
    )

    # 读取最新的验证数据，因为用户参与验证可能会同时发生
    v = Repo.reload(v)
    # 为等待状态才实施操作（超时处理）
    with :pending <- v.status,
         {:ok, v} <- Chats.update_verification(v, %{status: :timeout}) do
      Chats.update_verification(v, %{status: :timeout})
      # 写入验证数据点（超时）
      Stats.write(v)
      # 添加操作记录
      kmethod = scheme.timeout_killing_method || default!(:strategy)
      create_operation(v, kmethod, :system)
      # 计数器自增（超时总数）
      PolicrMini.Counter.increment(:verification_timeout_total)
      # 击杀用户（原因为超时）
      kill(v, scheme, :timeout)
      # 更新或删除入口消息
      put_or_delete_entry_message(v.chat_id, scheme)
    else
      {:error, reason} ->
        Logger.error("[#{v.id}] Verification timeout handling failed: #{inspect(reason: reason)}")

      status when is_atom(status) ->
        Logger.debug("[#{v.id}] Verification has ended, ignore timeout handing")
    end

    Logger.debug(
      "[#{v.id}] Verification handling has ended for timeout: #{inspect(chat_id: chat_id, user_id: user_id)}"
    )

    # 从缓存中删除任务
    JobCacher.delete_job(job_key(:terminate, v))

    :ok
  end

  @type operation_status :: :manual_ban | :manual_kick

  @doc """
  手动终止验证。
  """
  @spec manual_terminate(Verification.t(), operation_status) :: :ok
  def manual_terminate(veri = v, status) when status in [:manual_ban, :manual_kick] do
    %{chat_id: chat_id, target_user_id: user_id} = veri

    Logger.debug(
      "[#{v.id}] Manual verification termination started: #{inspect(chat_id: chat_id, user_id: user_id)}"
    )

    # 为等待状态才实施操作
    with :pending <- v.status,
         {:ok, v} <- Chats.update_verification(v, %{status: status}) do
      # 写入验证数据点（其它）
      Stats.write(v)

      # 终止超时处理任务
      :ok = PolicrMiniBot.Worker.cancel_terminate_validation_job(chat_id, user_id)

      scheme = Chats.find_or_init_scheme!(chat_id)

      Logger.debug(
        "[#{v.id}] Verification manually terminated by the administrator: #{inspect(chat_id: chat_id, user_id: user_id)}"
      )

      k = if status == :manual_ban, do: :ban, else: :kick

      # 添加操作记录
      create_operation(v, k, :admin)

      # 更新状态为
      Chats.update_verification(veri, %{status: status})
      # 击杀用户（原因即状态）
      kill(veri, scheme, status)
      # 更新或删除入口消息
      put_or_delete_entry_message(v.chat_id, scheme)

      Logger.debug(
        "[#{v.id}] Manual verification termination completed: #{inspect(chat_id: chat_id, user_id: user_id)}"
      )

      # 从缓存中删除任务
      JobCacher.delete_job(job_key(:terminate, veri))
    else
      {:error, reason} ->
        Logger.error(
          "[#{v.id}] Manual verification termination failed: #{inspect(reason: reason)}"
        )

      status when is_atom(status) ->
        Logger.debug("[#{v.id}] Verification has ended, ignore termination")
    end

    :ok
  end

  # 添加操作记录（系统）
  defp create_operation(verification, killing_method, role) when role in [:system, :admin] do
    action = if killing_method == :ban, do: :ban, else: :kick

    params = %{
      chat_id: verification.chat_id,
      verification_id: verification.id,
      action: action,
      role: role
    }

    case Chats.create_operation(params) do
      {:ok, _} = r ->
        r

      {:error, reason} = e ->
        Logger.error("Creating operation failed: #{inspect(reason: reason)}")

        e
    end
  end

  @spec async_terminate(Verification.t(), Scheme.t(), integer) :: Honeydew.Job.t()
  def async_terminate(v, scheme, waiting_secs) do
    %{chat_id: chat_id, target_user_id: user_id} = v
    job_key = job_key(:terminate, v)

    if job = JobCacher.get_job(job_key) do
      # 已存在

      Logger.debug(
        "[#{v.id}] Verification termination job already exists: #{inspect(chat_id: chat_id, user_id: user_id)}"
      )

      job
    else
      fun = {:terminate, [v, scheme, waiting_secs]}
      job = Honeydew.async(fun, @queue_name, delay_secs: waiting_secs)

      JobCacher.add_job(job_key, job)

      msg =
        "Async verification termination job has been created: #{inspect(chat_id: chat_id, user_id: user_id, waiting_secs: waiting_secs)}"

      Logger.debug(msg)

      job
    end
  end
end
