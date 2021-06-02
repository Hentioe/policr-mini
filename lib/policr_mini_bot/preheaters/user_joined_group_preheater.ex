defmodule PolicrMiniBot.UserJoinedGroupPreheater do
  @moduledoc """
  用户加入群组的处理器。

  """

  # TODO: 弃用此模块。由于 TG 上游的变动，加群已放弃对 `message` 的处理。因此 `telegex_plug` 库的预制的抽象模块已无法适应此需求，需改进库设计。

  # !注意! 此模块功能依赖对 `chat_member` 更新的接收。

  use PolicrMiniBot, plug: :preheater

  alias PolicrMiniBot.UserJoinedHandler
  alias PolicrMini.{Logger, SchemeBusiness}

  @doc """
  根据更新消息中的 `chat_member` 字段，验证用户。

  ## 以下情况将不进入验证流程：
  - 群组未接管。
  - 新成员状态不是 `member`。
  - 拉人或进群的是管理员。
  - 拉人或进群的是机器人。
  """

  # !注意! 因为以上的验证排除条件，此模块需要保证在填充以上条件的模块的处理流程的后面。
  @impl true
  def call(%{chat_member: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{new_chat_member: %{status: status}}} = _update, state)
      when status != "member" do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{takeovered: false} = state) do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{from_admin: true} = state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: chat_member} = _update, state) do
    %{chat: %{id: chat_id}, new_chat_member: %{user: new_user}, date: date} = chat_member

    case SchemeBusiness.fetch(chat_id) do
      {:ok, scheme} ->
        UserJoinedHandler.handle_one(chat_id, new_user, date, scheme, state)

      e ->
        Logger.unitized_error("Verification scheme fetching", chat_id: chat_id, returns: e)

        send_message(chat_id, t("errors.scheme_fetch_failed"))

        {:error, state}
    end
  end
end
