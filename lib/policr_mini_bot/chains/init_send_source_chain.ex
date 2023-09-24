defmodule PolicrMiniBot.InitSendSourceChain do
  @moduledoc false

  use PolicrMiniBot.Chain

  import PolicrMiniBot.Helper.FromParser

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
