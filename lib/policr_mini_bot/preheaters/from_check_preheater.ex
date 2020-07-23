defmodule PolicrMiniBot.FromCheckPreheater do
  @moduledoc """
  检查并缓存来源信息的预热器。
  """

  use PolicrMiniBot, plug: :preheater

  alias PolicrMini.PermissionBusiness

  @doc """
  检查更新内容中的来源信息，填充状态中的相关字段。

  此函数会填充 `PolicrMiniBot.State` 结构中的 `from_admin` 字段和 `from_self` 字段。
  当前此函数只支持了对新消息和回调的相关数据检查，暂时没有对其它消息类型进行支持。
  """
  @impl true
  def call(update, state) do
    case find_infomation(update) do
      {chat_id, user_id} ->
        from_admin = PermissionBusiness.find(chat_id, user_id) != nil
        from_self = user_id == PolicrMiniBot.id()

        state = %{state | from_admin: from_admin, from_self: from_self}

        {:ok, state}

      _ ->
        {:ignored, state}
    end
  end

  @spec find_infomation(Telegex.Model.Update.t()) :: {integer(), integer()} | nil
  defp find_infomation(update) do
    cond do
      update.message != nil ->
        %{chat: %{id: chat_id}, from: %{id: user_id}} = update.message

        {chat_id, user_id}

      update.callback_query != nil ->
        %{message: %{chat: %{id: chat_id}}, from: %{id: user_id}} = update.callback_query

        {chat_id, user_id}

      # 注意：未来此处可能要补充对数据的匹配
      true ->
        nil
    end
  end
end
