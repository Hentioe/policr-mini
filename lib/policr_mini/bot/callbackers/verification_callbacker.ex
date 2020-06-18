defmodule PolicrMini.Bot.VerificationCallbacker do
  @moduledoc """
  验证回调处理模块。
  """

  use PolicrMini.Bot.Callbacker, :verification

  alias PolicrMini.Schema.Verification
  alias PolicrMini.{VerificationBusiness, SchemeBusiness}
  alias PolicrMini.Bot.UserJoinedHandler

  @doc """
  回调处理函数。
  此函数仅仅解析参数并分发到其它子句中。
  """
  @impl true
  def handle(%{data: data} = callback_query) do
    data |> parse_callback_data() |> handle_data(callback_query)
  end

  @spec handle_data({String.t(), [String.t(), ...]}, Nadia.Model.CallbackQuery.t()) ::
          :error | :ok
  @doc """
  处理 v1 版本的验证。
  此版本的数据参数格式为「被选择答案索引:验证编号」。
  TODO: 应该根据验证记录中的入口动态决定的 chat_id（当前因为默认私聊的关系直接使用了 user_id）。
  """
  def handle_data({"v1", [chosen, verification_id]}, callback_query) do
    %{id: callback_query_id, from: %{id: user_id} = from, message: %{message_id: message_id}} =
      callback_query

    chosen = chosen |> String.to_integer()
    verification_id = verification_id |> String.to_integer()

    with {:ok, verification} <- validity_check(user_id, verification_id),
         {:ok, scheme} <- SchemeBusiness.fetch(verification.chat_id) do
      # 根据回答实施操作
      if Enum.member?(verification.indices, chosen) do
        # 回答正确：更新验证记录的状态、解除限制并发送通知消息
        {:ok, _} = verification |> VerificationBusiness.update(%{status: :passed})
        derestrict_chat_member(verification.chat_id, user_id)
        success_text = "恭喜您，验证通过。如果限制仍未解除请联系管理员。"

        async(fn -> edit_message(user_id, message_id, success_text) end)

        # 发送通知消息并延迟删除
        seconds = DateTime.diff(DateTime.utc_now(), verification.inserted_at)
        text = "刚刚#{at(from)}通过了验证，用时 #{seconds} 秒。"

        {:ok, sended_message} = send_message(verification.chat_id, text)
        delete_message(verification.chat_id, sended_message.message_id, delay_seconds: 8)
      else
        # 回答错误：更新验证记录的状态、根据方案实施操作并发送通知消息
        {:ok, _} = verification |> VerificationBusiness.update(%{status: :wronged})
        killing_method = scheme.killing_method || default!(:kmethod)

        case killing_method do
          :kick ->
            text = "抱歉，验证错误。您已被移出群组，稍后可尝试重新加入。"

            async(fn -> edit_message(user_id, message_id, text) end)

            target_user = %{id: user_id, fullname: verification.target_user_name}
            UserJoinedHandler.kick(verification.chat_id, target_user, :wronged)
        end
      end

      # 更新验证记录中的选择索引
      {:ok, _} = verification |> VerificationBusiness.update(%{chosen: chosen})

      count = VerificationBusiness.get_unity_waiting_count(verification.chat_id)

      if count == 0 do
        # 如果没有等待验证了，立即删除入口消息
        Nadia.delete_message(verification.chat_id, verification.message_id)
      else
        # 如果还存在多条验证，更新入口消息
        max_seconds = scheme.seconds || UserJoinedHandler.countdown()
        update_unity_verification_message(verification.chat_id, count, max_seconds)
      end

      :ok
    else
      {:error, %Ecto.Changeset{} = _} ->
        # TODO: 记录错误
        message = "出现了一些未意料的错误，校验验证时失败。请管理员并通知作者。"
        Nadia.answer_callback_query(callback_query_id, text: message, show_alert: true)

      {:error, message} ->
        Nadia.answer_callback_query(callback_query_id, text: message, show_alert: true)

        :error
    end
  end

  @spec update_unity_verification_message(integer(), integer(), integer()) ::
          :not_found | {:error, Nadia.Model.Error.t()} | {:ok, Nadia.Model.Message.t()}
  @doc """
  更新统一验证入口消息
  """
  def update_unity_verification_message(chat_id, count, max_seconds) do
    # 提及当前最新的等待验证记录中的用户
    if verification = VerificationBusiness.find_last_unity_waiting(chat_id) do
      user = %{id: verification.target_user_id, fullname: verification.target_user_name}

      {text, markup} = UserJoinedHandler.make_unity_message(chat_id, user, count, max_seconds)

      # 获取最新的验证入口消息编号
      message_id = VerificationBusiness.find_last_unity_message_id(chat_id)

      edit_message(chat_id, message_id, text, reply_markup: markup)
    else
      :not_found
    end
  end

  @spec validity_check(integer(), integer()) :: {:ok, Verification.t()} | {:error, String.t()}
  @doc """
  检查验证数据是否有效。
  """
  def validity_check(user_id, verification_id)
      when is_integer(user_id) and is_integer(verification_id) do
    with {:ok, verification} <- VerificationBusiness.get(verification_id),
         {:check_user, true} <- {:check_user, verification.target_user_id == user_id},
         {:check_status, true} <- {:check_status, verification.status == :waiting} do
      {:ok, verification}
    else
      {:error, :not_found, _} -> {:error, "没有找到和这条验证有关的记录哦～"}
      {:check_user, false} -> {:error, "此条验证并不针对你～"}
      {:check_status, false} -> {:error, "这条验证可能已经失效了～"}
    end
  end
end
