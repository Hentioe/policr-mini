defmodule PolicrMiniBot.HandleUserJoinedGroupPlug do
  @moduledoc """
  用户加入群组的处理器。
  """

  # TODO: 弃用此模块。由于 TG 上游的变动，加群已放弃对 `message` 的处理。因此 `telegex_plug` 库的预制的抽象模块已无法适应此需求，需改进库设计。

  # !注意! 此模块功能依赖对 `chat_member` 更新的接收。

  use PolicrMiniBot, plug: :preheater

  alias PolicrMiniBot.HandleUserJoinedCleanupPlug
  alias PolicrMini.{Logger, SchemeBusiness}

  @doc """
  根据更新消息中的 `chat_member` 字段，验证用户。

  ## 以下情况将不进入处理流程（按顺序匹配）：
  - 更新来自频道。
  - 群组未接管。
  - 状态中的动作不是 `:user_joined`。
  - 拉人或进群的是管理员。
  - 拉人或进群的是机器人。
  """

  # !注意! 由于匹配过程依赖状态中的 `action` 字段，此模块需要位于管道中的涉及填充相关状态字段、相关值的插件后面。
  # 当前此模块需要保证位于 `PolicrMiniBot.InitUserJoinedActionPlug` 模块的后面。
  @impl true
  def call(%{chat_member: nil} = _update, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{chat: %{type: "channel"}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{takeovered: false} = state) do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{action: action} = state) when action != :user_joined do
    {:ignored, state}
  end

  @impl true
  def call(_update, %{from_admin: true} = state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: %{new_chat_member: %{user: %{is_bot: true}}}}, state) do
    {:ignored, state}
  end

  @impl true
  def call(%{chat_member: chat_member} = _update, state) do
    %{chat: %{id: chat_id}, new_chat_member: %{user: new_user}, date: date} = chat_member

    Logger.debug("A new member (#{new_user.id}) has joined the group (#{chat_id}).")

    case SchemeBusiness.fetch(chat_id) do
      {:ok, scheme} ->
        HandleUserJoinedCleanupPlug.handle_one(chat_id, new_user, date, scheme, state)

      e ->
        Logger.unitized_error("Verification scheme fetching", chat_id: chat_id, returns: e)

        send_message(chat_id, t("errors.scheme_fetch_failed"))

        {:error, state}
    end
  end
end
