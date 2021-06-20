defmodule PolicrMiniBot.CallVerificationPlug do
  @moduledoc """
  验证回调处理模块。
  """

  use PolicrMiniBot, plug: [caller: [prefix: "verification:"]]

  alias PolicrMini.Logger
  alias PolicrMini.Schema.Verification
  alias PolicrMini.{VerificationBusiness, StatisticBusiness, SchemeBusiness, OperationBusiness}
  alias PolicrMiniBot.{HandleUserJoinedCleanupPlug, Disposable}

  @doc """
  回调处理函数。

  此函数仅仅解析参数并分发到 `handle_data/2` 子句中。
  """
  @impl true
  def handle(%{data: data} = callback_query, _state) do
    %{id: callback_query_id, message: %{message_id: message_id, chat: %{id: chat_id}}} =
      callback_query

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
        Telegex.answer_callback_query(callback_query_id, text: "有请求正在处理中……", show_alert: true)

        :error

      {:repeat, :done} ->
        Telegex.answer_callback_query(callback_query_id, text: "此任务已被处理过了～", show_alert: true)

        :error
    end
  end

  @doc """
  处理 v1 版本的验证。

  此版本的数据参数格式为「被选择答案索引:验证编号」。
  TODO: 应该根据验证记录中的入口动态决定的 chat_id（当前因为默认私聊的关系直接使用了 user_id）。
  """
  @spec handle_data({String.t(), [String.t(), ...]}, CallbackQuery.t()) :: :error | :ok
  def handle_data({"v1", [chosen, verification_id]}, callback_query) do
    %{id: callback_query_id, from: %{id: user_id} = from, message: %{message_id: message_id}} =
      callback_query

    chosen = chosen |> String.to_integer()
    verification_id = verification_id |> String.to_integer()

    handle_answer = fn verification, wrong_killing_method ->
      if Enum.member?(verification.indices, chosen) do
        # 处理回答正确
        handle_correct(verification, message_id, from)
      else
        # 处理回答错误
        handle_wrong(verification, wrong_killing_method, message_id, from)
      end
    end

    with {:ok, verification} <- validity_check(user_id, verification_id),
         {:ok, scheme} <- SchemeBusiness.fetch(verification.chat_id),
         # 处理回答。
         {:ok, verification} <- handle_answer.(verification, scheme.wrong_killing_method),
         # 更新验证记录中的选择索引
         {:ok, _} <- VerificationBusiness.update(verification, %{chosen: chosen}) do
      count = VerificationBusiness.get_unity_waiting_count(verification.chat_id)

      # 如果没有等待验证了，立即删除入口消息
      if count == 0 do
        # 获取最新的验证入口消息编号
        Cleaner.delete_latest_verification_message(verification.chat_id)
      else
        # 如果还存在多条验证，更新入口消息
        max_seconds = scheme.seconds || HandleUserJoinedCleanupPlug.countdown()
        update_unity_message(verification.chat_id, count, max_seconds)
      end

      :ok
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.unitized_error("Answer verification processing", changeset)

        answer_callback_query(callback_query_id,
          text: t("errors.check_answer_failed"),
          show_alert: true
        )

        :error

      {:error, :known, message} ->
        answer_callback_query(callback_query_id, text: message, show_alert: true)

        :error

      e ->
        answer_callback_query(callback_query_id, text: t("errors.unknown"), show_alert: true)

        Logger.unitized_error("Answer verification processing", e)
    end
  end

  @doc """
  处理回答正确。
  """
  @spec handle_correct(Verification.t(), integer(), Telegex.Model.User.t()) ::
          {:ok, Verification.t()} | {:error, any()}
  def handle_correct(verification, message_id, from_user) do
    # 自增统计数据（通过）。
    async do
      StatisticBusiness.increment_one(
        verification.chat_id,
        verification.target_user_language_code,
        :passed
      )
    end

    # 计数器自增（通过总数）
    PolicrMini.Counter.increment(:verification_passed_total)
    # 发送通知消息并延迟删除
    notice_fun = fn ->
      marked_enabled = Application.get_env(:policr_mini, :marked_enabled)
      seconds = DateTime.diff(DateTime.utc_now(), verification.inserted_at)

      text =
        t("verification.passed.notice", %{
          mentioned_user: mention(from_user, anonymization: !marked_enabled),
          seconds: seconds
        })

      case send_message(verification.chat_id, text, parse_mode: "MarkdownV2ToHTML") do
        {:ok, sended_message} ->
          Cleaner.delete_message(verification.chat_id, sended_message.message_id, delay_seconds: 8)

        e ->
          Logger.unitized_error("Verification passed notification", e)
      end
    end

    case verification |> VerificationBusiness.update(%{status: :passed}) do
      {:ok, verification} ->
        # 解除限制
        async(fn -> derestrict_chat_member(verification.chat_id, verification.target_user_id) end)
        # 更新验证结果
        async(fn ->
          Cleaner.delete_message(verification.target_user_id, message_id)
          send_message(verification.target_user_id, t("verification.passed.private"))
        end)

        async(fn -> verification.chat_id |> typing() end)

        # 发送通知
        async(notice_fun)

        {:ok, verification}

      e ->
        e
    end
  end

  @doc """
  处理错误回答。

  将根据验证方案中的配置选择击杀方式对应的处理逻辑。
  """
  @spec handle_wrong(Verification.t(), atom, integer, Telegex.Model.User.t()) ::
          {:ok, Verification.t()} | {:error, any}
  def handle_wrong(verification, wrong_killing_method, message_id, from_user) do
    # 自增统计数据（错误）。
    async do
      StatisticBusiness.increment_one(
        verification.chat_id,
        verification.target_user_language_code,
        :wronged
      )
    end

    cleaner_fun = fn notice_text ->
      async do
        Cleaner.delete_message(verification.target_user_id, message_id)
        send_message(verification.target_user_id, notice_text)
      end
    end

    operation_create_fun = fn verification ->
      operation_action = if wrong_killing_method == :ban, do: :ban, else: :kick

      case OperationBusiness.create(%{
             verification_id: verification.id,
             action: operation_action,
             role: :system
           }) do
        {:ok, _} = r ->
          r

        e ->
          Logger.unitized_error("Operation creation", e)

          e
      end
    end

    case verification |> VerificationBusiness.update(%{status: :wronged}) do
      {:ok, verification} ->
        # 添加操作记录（系统）。
        operation_create_fun.(verification)
        cleaner_fun.(t("verification.wronged.#{wrong_killing_method || :kick}.private"))

        kill(
          verification.chat_id,
          from_user,
          :wronged,
          wrong_killing_method
        )

        {:ok, verification}

      e ->
        e
    end
  end

  @doc """
  更新统一验证入口消息
  """
  @spec update_unity_message(integer(), integer(), integer()) ::
          :not_found | {:error, Telegex.Model.errors()} | {:ok, Message.t()}
  def update_unity_message(chat_id, count, max_seconds) do
    # 提及当前最新的等待验证记录中的用户
    if verification = VerificationBusiness.find_last_unity_waiting(chat_id) do
      user = %{id: verification.target_user_id, fullname: verification.target_user_name}

      {text, markup} =
        HandleUserJoinedCleanupPlug.make_unity_content(chat_id, user, count, max_seconds)

      # 获取最新的验证入口消息编号
      message_id = VerificationBusiness.find_last_unity_message_id(chat_id)

      edit_message_text(text, chat_id: chat_id, message_id: message_id, reply_markup: markup)
    else
      :not_found
    end
  end

  @doc """
  检查验证数据是否有效。
  """
  @spec validity_check(integer(), integer()) :: {:ok, Verification.t()} | {:error, String.t()}
  def validity_check(user_id, verification_id) do
    with {:ok, verification} <- VerificationBusiness.get(verification_id),
         {:check_user, true} <- {:check_user, verification.target_user_id == user_id},
         {:check_status, true} <- {:check_status, verification.status == :waiting} do
      {:ok, verification}
    else
      {:error, :not_found, _} -> {:error, :known, t("errors.verification_not_found")}
      {:check_user, false} -> {:error, :known, t("errors.verification_target_incorrect")}
      {:check_status, false} -> {:error, :known, t("errors.verification_expired")}
    end
  end

  @doc """
  获取允许重新加入时长。
  当前的实现会根据运行模式返回不同的值。
  """
  @spec allow_join_again_seconds :: integer()
  def allow_join_again_seconds do
    if PolicrMini.mix_env() == :dev, do: 15, else: 60 * 2
  end

  @doc """
  击杀用户。

  此函数会根据击杀方法做出指定动作，并结合击杀原因发送通知消息。若 `method` 参数的值为 `nil`，则默认表示击杀方法为 `:kick`。
  """
  @spec kill(integer, map, :wronged | :timeout, :kick | :ban | nil) :: :ok | {:error, map}
  def kill(chat_id, user, reason, method) do
    method = method || :kick

    case method do
      :kick ->
        Telegex.kick_chat_member(chat_id, user.id)
        # 解除限制以允许再次加入。
        async(fn -> Telegex.unban_chat_member(chat_id, user.id) end,
          seconds: allow_join_again_seconds()
        )

      :ban ->
        Telegex.kick_chat_member(chat_id, user.id)
    end

    time_text =
      if allow_join_again_seconds() < 60,
        do: "#{allow_join_again_seconds()} #{t("units.sec")}",
        else: "#{to_string(trunc(allow_join_again_seconds() / 60))} #{t("units.min")}"

    text =
      case reason do
        :timeout ->
          t("verification.timeout.#{method}.public", %{
            mentioned_user: mention(user, anonymization: false, mosaic: true),
            time_text: time_text
          })

        :wronged ->
          t("verification.wronged.#{method}.public", %{
            mentioned_user: mention(user, anonymization: false, mosaic: true),
            time_text: time_text
          })
      end

    async(fn -> chat_id |> typing() end)

    case send_message(chat_id, text, parse_mode: "MarkdownV2ToHTML") do
      {:ok, sended_message} ->
        Cleaner.delete_message(chat_id, sended_message.message_id, delay_seconds: 8)

        :ok

      e ->
        Logger.unitized_error("Send notification of user killed",
          chat_id: chat_id,
          user_id: user.id,
          returns: e
        )

        e
    end
  end
end
