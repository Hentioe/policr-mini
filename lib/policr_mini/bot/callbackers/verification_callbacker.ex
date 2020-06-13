defmodule PolicrMini.Bot.VerificationCallbacker do
  @moduledoc """
  验证回调处理模块。
  """

  use PolicrMini.Bot.Callbacker, :verification

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

  @doc """
  处理 v1 版本的验证。
  TODO: 实现中一部分应该由验证记录中的入口动态决定的 chat_id 被临时使用了 user_id，待完善。
  """
  def handle_data(
        {"v1", [chosen, verification_id]},
        %{id: callback_query_id, from: %{id: user_id} = from, message: %{message_id: message_id}} =
          _callback_query
      ) do
    chosen = chosen |> String.to_integer()

    case VerificationBusiness.get(verification_id) do
      {:ok, verification} ->
        # 判断验证是否有效
        if verification.target_user_id != user_id do
          Nadia.answer_callback_query(callback_query_id, text: "此条验证并不针对你哦～", show_alert: true)
        end

        if verification.status != :waiting do
          Nadia.answer_callback_query(callback_query_id, text: "这条验证可能已经失效了～", show_alert: true)
        end

        is_passed? = Enum.member?(verification.indices, chosen)
        # 根据回答实施操作
        if is_passed? do
          # 回答正确：更新验证记录的状态、解除限制并发送通知消息
          {:ok, _} = verification |> VerificationBusiness.update(%{status: :passed})
          :ok = derestrict_chat_member(verification.chat_id, user_id)

          success_text = "恭喜您，验证通过。去试试自己的限制是否被解除吧。"

          async(fn ->
            edit_message(user_id, message_id, success_text)
          end)

          seconds = DateTime.diff(DateTime.utc_now(), verification.inserted_at)
          text = "刚刚#{at(from)}通过了验证，用时 #{seconds} 秒。"

          case send_message(verification.chat_id, text) do
            {:ok, sended_message} ->
              async(
                fn ->
                  Nadia.delete_message(verification.chat_id, sended_message.message_id)
                end,
                seconds: 15
              )
          end
        else
          # 回答错误：更新验证记录的状态、根据方案实施操作并发送通知消息
          {:ok, _} = verification |> VerificationBusiness.update(%{status: :wronged})
          {:ok, scheme} = SchemeBusiness.fetch(verification.chat_id)
          killing_method = scheme.killing_method || :kick

          case killing_method do
            :kick ->
              text = "抱歉，验证错误。您已被移出群组，稍后可尝试重新加入。"

              async(fn ->
                edit_message(user_id, message_id, text)
              end)

              UserJoinedHandler.kick(
                verification.chat_id,
                %{id: user_id, fullname: verification.target_user_name},
                :wronged
              )
          end
        end

        # 更新验证记录中的选择索引
        {:ok, _} = verification |> VerificationBusiness.update(%{chosen: chosen})

        # 如果没有等待验证了，立即删除入口消息
        count = VerificationBusiness.get_unity_waiting_count(verification.chat_id)
        if count == 0, do: Nadia.delete_message(verification.chat_id, verification.message_id)
        # TODO: 如果还存在多条验证，更新入口消息
        :ok

      {:error, :not_found, _} ->
        Nadia.answer_callback_query(callback_query_id, text: "没有找到和这条验证有关的记录哦～", show_alert: true)

        :error
    end
  end
end
