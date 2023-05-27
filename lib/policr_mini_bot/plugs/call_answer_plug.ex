defmodule PolicrMiniBot.CallAnswerPlug do
  @moduledoc """
  验证回调处理模块。
  """

  use PolicrMiniBot, plug: [caller: [prefix: "ans:"]]

  alias PolicrMini.{Chats, Counter}
  alias PolicrMini.Chats.{Verification, Scheme, Operation}
  alias PolicrMiniBot.{Disposable, Worker}
  alias Telegex.Model.User, as: TgUser

  import PolicrMiniBot.VerificationHelper

  require Logger

  @impl true
  def handle(%{data: data} = callback_query, _state) do
    %{
      id: callback_query_id,
      message: %{message_id: message_id, chat: %{id: chat_id}}
    } = callback_query

    processing_key = "#{chat_id}_#{message_id}"

    case Disposable.processing(processing_key) do
      :ok ->
        result =
          data
          |> parse_callback_data()
          |> handle_data(callback_query)

        Disposable.done(processing_key)

        result

      {:repeat, :processing} ->
        Telegex.answer_callback_query(callback_query_id,
          text: commands_text("有请求正在处理中…"),
          show_alert: true
        )

        :error

      {:repeat, :done} ->
        Telegex.answer_callback_query(callback_query_id,
          text: commands_text("此任务已被处理过了～"),
          show_alert: true
        )

        :error
    end
  end

  @doc """
  处理 v1 版本的验证。

  此版本的数据参数格式为「被选择答案索引:验证编号」。
  TODO: 应该根据验证记录中的入口动态决定的 chat_id（当前因为默认私聊的关系直接使用了 user_id）。
  """
  @spec handle_data({String.t(), [String.t(), ...]}, CallbackQuery.t()) ::
          :error | :ok
  def handle_data({"v1", [chosen, vid]}, callback_query) do
    %{
      id: callback_query_id,
      from: %{id: user_id}
    } = callback_query

    chosen = String.to_integer(chosen)
    vid = String.to_integer(vid)

    # 1. 检查验证有效性
    # 2. 更新选择数据
    # 3. 获取群组方案
    # 4. 处理回答
    with {:ok, v} <- validity_check(user_id, vid),
         {:ok, v} <- Chats.update_verification(v, %{chosen: chosen}),
         {:ok, scheme} <- Chats.find_or_init_scheme(v.chat_id),
         {:ok, v} <- handle_answer(v, scheme, callback_query) do
      # 验证处理结束，更新或删除入口消息
      put_or_delete_entry_message(v, scheme)

      :ok
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Processing of verification answer failed: #{inspect(reason: changeset)}")

        answer_callback_query(callback_query_id,
          text: t("errors.check_answer_failed"),
          show_alert: true
        )

        :error

      {:error, :known, message} ->
        answer_callback_query(callback_query_id, text: message, show_alert: true)

        :error

      {:error, reason} ->
        answer_callback_query(callback_query_id,
          text: t("errors.unknown"),
          show_alert: true
        )

        Logger.error("Processing of verification answer failed: #{inspect(reason: reason)}")

        :error
    end
  end

  @doc """
  处理答案。
  """
  @spec handle_answer(Verification.t(), Scheme.t(), CallbackQuery.t()) ::
          {:ok, Verification.t()} | {:error, any}
  def handle_answer(v, scheme, callback_query) do
    %{
      from: from,
      message: %{message_id: message_id}
    } = callback_query

    # 取消超时任务
    Worker.cancel_terminate_validation_job(
      v.chat_id,
      v.target_user_id
    )

    if Enum.member?(v.indices, v.chosen) do
      # 处理回答正确
      handle_correct_answer(v, message_id, from)
    else
      # 处理回答错误
      handle_wrong_answer(v, scheme, message_id, from)
    end
  end

  @doc """
  处理回答正确。
  """
  @spec handle_correct_answer(Verification.t(), integer, TgUser.t()) ::
          {:ok, Verification.t()} | {:error, any()}
  def handle_correct_answer(%{source: :joined} = v, message_id, from_user) do
    # 自增统计数据（通过）
    async_run(fn -> Chats.increment_statistic(v.chat_id, v.target_user_language_code, :passed) end)

    # 计数器自增（通过的总数）
    Counter.increment(:verification_passed_total)

    case Chats.update_verification(v, %{status: :passed}) do
      {:ok, v} = ok_r ->
        # 异步解除限制
        async_run(fn -> derestrict_chat_member(v.chat_id, v.target_user_id) end)

        # 更新验证消息为验证结果
        async_update_result(v, message_id)

        # 发送验证成功通知
        async_success_notify(v, from_user)

        ok_r

      e ->
        e
    end
  end

  @spec async_update_result(Verification.t(), integer) :: :ok
  defp async_update_result(v, message_id) do
    async do
      # 注意：此处默认以 `Telegex.Marked` 库转换文字，需要用 `escape_markdown/1` 函数转义文本中的动态内容。
      text =
        t("verification.passed.private", %{
          chat_title: escape_markdown(v.chat.title)
        })

      Worker.async_delete_message(v.target_user_id, message_id)

      send_message(v.target_user_id, text, parse_mode: "MarkdownV2ToHTML")
    end

    :ok
  end

  @spec async_success_notify(Verification.t(), TgUser.t()) :: :ok
  defp async_success_notify(v, user) do
    async do
      marked_enabled = Application.get_env(:policr_mini, :marked_enabled)
      seconds = DateTime.diff(DateTime.utc_now(), v.inserted_at)

      text =
        t("verification.passed.notice", %{
          mentioned_user: mention(user, anonymization: !marked_enabled),
          seconds: seconds
        })

      case send_message(v.chat_id, text, parse_mode: "MarkdownV2ToHTML") do
        {:ok, %{message_id: message_id}} ->
          # 延迟 8 秒删除通知消息
          Worker.async_delete_message(v.chat_id, message_id, delay_secs: 8)

        {:error, reason} ->
          Logger.error("Send notification failed: #{inspect(reason: reason)}",
            chat_id: v.chat_id
          )
      end
    end

    :ok
  end

  @doc """
  处理错误回答。
  """
  @spec handle_wrong_answer(Verification.t(), Scheme.t(), integer, TgUser.t()) ::
          {:ok, Verification.t()} | {:error, any}
  def handle_wrong_answer(v, scheme, message_id, user) do
    # 获取方案中的配置项
    wkmethod = scheme.wrong_killing_method || default!(:wkmethod)
    delay_unban_secs = scheme.delay_unban_secs || default!(:delay_unban_secs)
    # 自增统计数据（错误）
    async_run(fn ->
      Chats.increment_statistic(v.chat_id, v.target_user_language_code, :wronged)
    end)

    case Chats.update_verification(v, %{status: :wronged}) do
      {:ok, v} ->
        # 添加操作记录
        add_operation(wkmethod, v)

        # 清理消息并私聊验证结果。
        async_clean_with_notify(message_id, v, wkmethod)

        # 击杀用户
        kill(v.chat_id, user, :wronged, wkmethod, delay_unban_secs)

        {:ok, v}

      e ->
        e
    end
  end

  @spec add_operation(atom, Verification.t()) :: {:ok, Operation.t()} | {:error, any}
  defp add_operation(kmethod, v) do
    action = if kmethod == :ban, do: :ban, else: :kick

    params = %{
      chat_id: v.chat_id,
      verification_id: v.id,
      action: action,
      role: :system
    }

    case Chats.create_operation(params) do
      {:ok, _} = ok_r ->
        ok_r

      {:error, reason} = e ->
        Logger.error("Create operation failed: #{inspect(reason: reason)}")

        e
    end
  end

  @spec async_clean_with_notify(integer, Verification.t(), atom) :: no_return
  defp async_clean_with_notify(message_id, v, kmethod) do
    async do
      # 注意：此处默认以 `Telegex.Marked` 库转换文字，需要用 `escape_markdown/1` 函数转义文本中的动态内容。
      text =
        t("verification.wronged.#{kmethod || :kick}.private", %{
          chat_title: escape_markdown(v.chat.title)
        })

      Worker.async_delete_message(v.target_user_id, message_id)

      send_message(v.target_user_id, text, parse_mode: "MarkdownV2ToHTML")
    end
  end

  @doc """
  检查验证数据是否有效。
  """
  @spec validity_check(integer(), integer()) :: {:ok, Verification.t()} | {:error, String.t()}
  def validity_check(user_id, verification_id) do
    # 1. 验证是否存在
    # 2. 验证是否是目标用户
    # 3. 验证是否未完成
    with {:ok, verification} <- Verification.get(verification_id, preload: [:chat]),
         {:check_user, true} <- {:check_user, verification.target_user_id == user_id},
         {:check_status, true} <- {:check_status, verification.status == :waiting} do
      # 返回验证记录
      {:ok, verification}
    else
      {:error, :not_found, _} ->
        {:error, :known, t("errors.verification_not_found")}

      {:check_user, false} ->
        {:error, :known, t("errors.verification_target_incorrect")}

      {:check_status, false} ->
        {:error, :known, t("errors.verification_expired")}
    end
  end

  @type killing_reason :: :wronged | :timeout | :kick | :ban | :manual_ban | :manual_kick
  @type killing_method :: :ban | :kick

  @doc """
  击杀用户。

  此函数会根据击杀方法做出指定动作，并结合击杀原因发送通知消息。若 `method` 参数的值为 `nil`，则默认表示击杀方法为 `:kick`。
  """
  @spec kill(integer | binary, map, killing_reason, killing_method, integer) ::
          :ok | {:error, map}
  def kill(chat_id, user, reason, method, delay_unban_secs) do
    method = method || :kick

    case method do
      :kick ->
        kick_chat_member(chat_id, user.id, delay_unban_secs)

      :ban ->
        Telegex.ban_chat_member(chat_id, user.id)
    end

    time_text = "#{delay_unban_secs} #{t("units.sec")}"
    mentioned_user = mention(user, anonymization: false, mosaic: true)

    text = build_kick_text(reason, method, mentioned_user, time_text)

    case send_message(chat_id, text, parse_mode: "MarkdownV2ToHTML") do
      {:ok, sended_message} ->
        Worker.async_delete_message(chat_id, sended_message.message_id, delay_secs: 8)

        :ok

      {:error, reason} = e ->
        Logger.warning(
          "Send kill user notification failed: #{inspect(chat_id: chat_id, user_id: user.id, reason: reason)}"
        )

        e
    end
  end

  # 构造击杀文字（公聊通知）
  @spec build_kick_text(killing_reason, killing_method, String.t(), String.t()) ::
          String.t()
  defp build_kick_text(:timeout, method, mentioned_user, time_text) do
    t("verification.timeout.#{method}.public", %{
      mentioned_user: mentioned_user,
      time_text: time_text
    })
  end

  defp build_kick_text(:wronged, method, mentioned_user, time_text) do
    t("verification.wronged.#{method}.public", %{
      mentioned_user: mentioned_user,
      time_text: time_text
    })
  end

  defp build_kick_text(:manual_ban, method, mentioned_user, _time_text) do
    t("verification.manual.#{method}.public", %{mentioned_user: mentioned_user})
  end

  defp build_kick_text(:manual_kick, method, mentioned_user, _time_text) do
    t("verification.manual.#{method}.public", %{mentioned_user: mentioned_user})
  end

  @spec kick_chat_member(integer, integer, integer) ::
          {:ok, boolean} | Telegex.Model.errors()
  defp kick_chat_member(chat_id, user_id, delay_unban_secs) do
    case PolicrMiniBot.config(:unban_method) do
      :api_call ->
        r = Telegex.ban_chat_member(chat_id, user_id)

        # 调用 API 解除限制以允许再次加入。
        async_run(fn -> Telegex.unban_chat_member(chat_id, user_id) end,
          delay_secs: delay_unban_secs
        )

        r

      :until_date ->
        Telegex.ban_chat_member(chat_id, user_id, until_date: until_date(delay_unban_secs))
    end
  end

  @spec until_date(integer) :: integer
  defp until_date(delay_unban_secs) do
    dt_now = DateTime.utc_now()
    unix_now = DateTime.to_unix(dt_now)

    # 当前时间加允许重现加入的秒数，确保能正常解除封禁。
    # +1 是为了抵消网络延迟
    unix_now + delay_unban_secs + 1
  end
end
