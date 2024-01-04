defmodule PolicrMiniBot.InitSendSourceChain do
  @moduledoc false

  use PolicrMiniBot.Chain

  import PolicrMiniBot.Helper.FromParser

  # 来自频道的新消息。
  @impl true
  def handle(%{channel_post: channel_post} = _update, context) when channel_post != nil do
    # 直接忽略，不继续传播链。

    {:stop, context}
  end

  @impl true
  def handle(update, context) do
    case parse(update) do
      {chat_id, user_id} ->
        context = %{context | chat_id: chat_id, user_id: user_id}

        {:ok, context}

      _ ->
        {:ok, context}
    end
  end
end
