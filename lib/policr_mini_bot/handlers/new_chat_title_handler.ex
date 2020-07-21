defmodule PolicrMiniBot.NewChatTitleHandler do
  @moduledoc """
  群组标题修改的处理器。
  """

  use PolicrMiniBot, plug: :handler

  require Logger

  alias PolicrMini.ChatBusiness

  @doc """
  匹配消息是否为群组标题修改。

  消息中的 `new_chat_title` 为 `nil` 时，表示不匹配。否则匹配。
  """
  @impl true
  def match(%{new_chat_title: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(_message, state), do: {:match, state}

  @doc """
  处理群组标题修改。

  更新数据库中对应的群组的标题数据。
  """
  @impl true
  def handle(message, state) do
    %{new_chat_title: new_chat_title, chat: %{id: chat_id}} = message

    case ChatBusiness.get(chat_id) do
      {:ok, chat} ->
        ChatBusiness.update(chat, %{title: new_chat_title})
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end
end
