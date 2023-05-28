defmodule PolicrMiniBot.CallAnswerPlug do
  @moduledoc """
  验证回调处理模块。
  """

  use PolicrMiniBot, plug: [caller: [prefix: "ans:"]]

  alias PolicrMini.{Chats, Counter}
  alias PolicrMini.Chats.{Verification, Scheme, Operation}
  alias PolicrMiniBot.{Disposable, Worker, JoinReuquestHosting}
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
      put_or_delete_entry_message(v.chat_id, scheme)

      :ok
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.error("Processing of verification answer failed: #{inspect(reason: changeset)}")

        answer_callback_query(callback_query_id,
          text: commands_text("答案校验失败，请管理员并通知开发者。"),
          show_alert: true
        )

        :error

      {:error, :known, message} ->
        answer_callback_query(callback_query_id, text: message, show_alert: true)

        :error

      {:error, reason} ->
        answer_callback_query(callback_query_id,
          text: commands_text("发生了一些未预料的情况，请向开发者反馈。"),
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
      handle_wrong_answer(v, scheme, message_id)
    end
  end

  @doc """
  处理回答正确。
  """
  @spec handle_correct_answer(Verification.t(), integer, TgUser.t()) ::
          {:ok, Verification.t()} | {:error, any()}
  def handle_correct_answer(v, message_id, from_user) do
    # 自增统计数据（通过）
    async_run(fn -> Chats.increment_statistic(v.chat_id, v.target_user_language_code, :passed) end)

    # 计数器自增（通过的总数）
    Counter.increment(:verification_passed_total)

    case Chats.update_verification(v, %{status: :passed}) do
      {:ok, v} = ok_r ->
        # 通过用户
        pass_user(v)

        # 更新验证消息为验证结果
        async_update_result(v, message_id)

        # 发送验证成功通知
        async_success_notify(v, from_user)

        ok_r

      e ->
        e
    end
  end

  # 根据不同来源，通过验证用户
  @spec pass_user(Verification.t()) :: :ok
  defp pass_user(%{source: :joined} = v) do
    async_run(fn -> derestrict_chat_member(v.chat_id, v.target_user_id) end)

    :ok
  end

  defp pass_user(%{source: :join_request} = v) do
    # 更新托管的请求中的状态
    :ok = JoinReuquestHosting.update_status(v.chat_id, v.target_user_id, :approved)

    async_run(fn -> Telegex.approve_chat_join_request(v.chat_id, v.target_user_id) end)

    :ok
  end

  @spec async_update_result(Verification.t(), integer) :: :ok
  defp async_update_result(v, message_id) do
    theader =
      commands_text("恭喜您通过了『%{chat_title}』的加群验证，权限已恢复。",
        chat_title: "*#{escape_markdown(v.chat.title)}*"
      )

    tfooter = commands_text("提示：如果限制仍未解除请主动联系群管理。")

    text = """
    #{theader}

    _#{tfooter}_
    """

    async do
      Worker.async_delete_message(v.target_user_id, message_id)

      send_message(v.target_user_id, text, parse_mode: "MarkdownV2")
    end

    :ok
  end

  @spec async_success_notify(Verification.t(), TgUser.t()) :: :ok
  defp async_success_notify(v, user) do
    seconds = DateTime.diff(DateTime.utc_now(), v.inserted_at)

    text =
      commands_text("刚刚 %{mention} 通过了验证，用时 %{seconds} 秒。",
        mention: mention(user, anonymization: false),
        seconds: seconds
      )

    async do
      case send_message(v.chat_id, text, parse_mode: "MarkdownV2") do
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
  @spec handle_wrong_answer(Verification.t(), Scheme.t(), integer) ::
          {:ok, Verification.t()} | {:error, any}
  def handle_wrong_answer(v, scheme, message_id) do
    # 获取方案中的配置项
    wkmethod = scheme.wrong_killing_method || default!(:wkmethod)
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
        kill(v, scheme, :wronged)

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
  defp async_clean_with_notify(message_id, %{source: :joined} = v, kmethod) do
    text =
      case kmethod do
        :ban ->
          commands_text("抱歉，您未通过『%{chat_title}』的加群验证。已被封禁。",
            chat_title: "*#{escape_markdown(v.chat.title)}*"
          )

        _ ->
          theader =
            commands_text("抱歉，您未通过『%{chat_title}』的加群验证。已被移出该群。",
              chat_title: "*#{escape_markdown(v.chat.title)}*"
            )

          tfooter = commands_text("提示：可稍后重新尝试，但无法立刻再次加入。")

          """
          #{theader}

          _#{tfooter}_
          """
      end

    async do
      Worker.async_delete_message(v.target_user_id, message_id)

      send_message(v.target_user_id, text, parse_mode: "MarkdownV2")
    end
  end

  defp async_clean_with_notify(message_id, %{source: :join_request} = v, kmethod) do
    text =
      case kmethod do
        :ban ->
          commands_text("抱歉，您未通过『%{chat_title}』的加群验证。已拒绝加入请求并被禁止再次申请加入。",
            chat_title: "*#{escape_markdown(v.chat.title)}*"
          )

        _ ->
          theader =
            commands_text("抱歉，您未通过『%{chat_title}』的加群验证。已拒绝加入请求。",
              chat_title: "*#{escape_markdown(v.chat.title)}*"
            )

          tfooter = commands_text("提示：可稍后重新尝试，但无法立刻再次申请加入。")

          """
          #{theader}

          _#{tfooter}_
          """
      end

    async do
      Worker.async_delete_message(v.target_user_id, message_id)

      send_message(v.target_user_id, text, parse_mode: "MarkdownV2")
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
        {:error, :known, commands_text("没有找到和这条验证有关的记录～")}

      {:check_user, false} ->
        {:error, :known, commands_text("此条验证并不针对你～")}

      {:check_status, false} ->
        {:error, :known, commands_text("这条验证可能已经失效了～")}
    end
  end
end
