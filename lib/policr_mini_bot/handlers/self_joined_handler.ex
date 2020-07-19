defmodule PolicrMiniBot.SelfJoinedHandler do
  @moduledoc """
  自身加入新群组的处理器。
  """

  use PolicrMiniBot.Handler

  require Logger

  alias PolicrMiniBot.SyncCommander

  @impl true
  def match?(%{new_chat_members: nil} = _message, state), do: {false, state}

  @doc """
  单个用户加入，判断用户编号
  """
  @impl true
  def match?(%{new_chat_members: [%{id: member_id}]} = _message, state),
    do: {member_id == bot_id(), state}

  @doc """
  多个用户加入，判断用户编号
  """
  def match?(%{new_chat_members: members} = _message, state),
    do: {members |> Enum.find(fn member -> member.id == bot_id() end) != nil, state}

  @impl true
  def handle(message, state) do
    chat_type = message.chat.type

    if chat_type != "supergroup", do: exits(chat_type, message), else: handle_it(message)

    {:ok, %{state | done: true}}
  end

  # 退出普通群。
  defp exits("group", message) do
    chat_id = message.chat.id

    send_message(chat_id, t("errors.no_super_group"))
    Telegex.leave_chat(chat_id)
  end

  # 退出频道。附加：目前测试被邀请进频道时并不会产生消息。
  defp exits("channel", message) do
    chat_id = message.chat.id

    Telegex.leave_chat(chat_id)
  end

  @spec handle_it(Telegex.Model.Message.t()) :: no_return()
  defp handle_it(message) do
    chat_id = message.chat.id

    # 同步群组和管理员信息
    with {:ok, chat} <- SyncCommander.synchronize_chat(chat_id, true),
         {:ok, _} <- SyncCommander.synchronize_administrators(chat),
         :ok <- response(chat_id) do
    else
      # 无发消息权限，直接退出
      {:error, %Telegex.Model.Error{description: "Bad Request: have no rights to send a message"}} ->
        Telegex.leave_chat(chat_id)

      e ->
        Logger.error("An error occurred after the bot was invited. Details: #{inspect(e)}")
        send_message(chat_id, t("self_joined.error"))
    end
  end

  @spec response(integer()) :: :ok | {:error, Telegex.Model.errors()}
  @doc """
  发送响应消息。
  """
  def response(chat_id) when is_integer(chat_id) do
    text = t("self_joined.text", %{bot_username: bot_username()})

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: t("self_joined.markup_text.subscribe"),
            url: "https://t.me/policr_changelog"
          }
        ]
      ]
    }

    case send_message(chat_id, text, reply_markup: markup, parse_mode: nil) do
      {:ok, _} -> :ok
      e -> e
    end
  end
end
