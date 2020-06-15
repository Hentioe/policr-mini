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

    case validity_check(user_id, verification_id) do
      {:ok, verification} ->
        # 根据回答实施操作
        if Enum.member?(verification.indices, chosen) do
          # 回答正确：更新验证记录的状态、解除限制并发送通知消息
          {:ok, _} = verification |> VerificationBusiness.update(%{status: :passed})
          :ok = derestrict_chat_member(verification.chat_id, user_id)
          success_text = "恭喜您，验证通过。如果限制仍未解除请尝试联系管理员。"

          async(fn -> edit_message(user_id, message_id, success_text) end)

          # 发送通知消息并延迟删除
          seconds = DateTime.diff(DateTime.utc_now(), verification.inserted_at)
          text = "刚刚#{at(from)}通过了验证，用时 #{seconds} 秒。"

          {:ok, sended_message} = send_message(verification.chat_id, text)
          delete_message(verification.chat_id, sended_message.message_id, delay_seconds: 15)
        else
          # 回答错误：更新验证记录的状态、根据方案实施操作并发送通知消息
          {:ok, _} = verification |> VerificationBusiness.update(%{status: :wronged})
          {:ok, scheme} = SchemeBusiness.fetch(verification.chat_id)
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

        # 如果没有等待验证了，立即删除入口消息
        count = VerificationBusiness.get_unity_waiting_count(verification.chat_id)
        if count == 0, do: Nadia.delete_message(verification.chat_id, verification.message_id)
        # TODO: 如果还存在多条验证，更新入口消息
        :ok

      {:error, message} ->
        Nadia.answer_callback_query(callback_query_id, text: message, show_alert: true)

        :error
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
