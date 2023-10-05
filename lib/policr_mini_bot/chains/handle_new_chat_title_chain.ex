defmodule PolicrMiniBot.HandleNewChatTitleChain do
  @moduledoc """
  处理新的群标题。

  ## 以下情况皆不匹配
    - 字段 `new_chat_title` 的值为空。
  """
  use PolicrMiniBot.Chain, :message

  alias PolicrMini.Instances
  alias PolicrMini.Instances.Chat

  require Logger

  # 忽略 `new_chat_title` 为空。
  @impl true
  def match?(%{new_chat_title: nil} = _message, _context), do: false

  # 其余皆匹配。
  @impl true
  def match?(_message, _context), do: true

  @impl true
  def handle(message, context) do
    %{new_chat_title: new_chat_title, chat: tg_chat} = message

    Logger.debug("New chat title: #{inspect(new_chat_title: new_chat_title)}",
      chat_id: tg_chat.id
    )

    case Chat.get(tg_chat.id) do
      {:ok, chat} ->
        Instances.update_chat(chat, %{title: new_chat_title})

        {:ok, context}

      {:error, :not_found, _} ->
        Logger.warning(
          "New non-persistent chat: #{inspect(occurs_in: :new_chat_title, new_chat_title: new_chat_title)}",
          chat_id: tg_chat.id
        )

        {:ok, context}
    end
  end
end
