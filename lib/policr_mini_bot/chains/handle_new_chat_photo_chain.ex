defmodule PolicrMiniBot.HandleNewChatPhotoChain do
  @moduledoc """
  处理新的群头像。

  ## 以下情况皆不匹配
    - 字段 `new_chat_photo` 的值为空。
  """

  use PolicrMiniBot.Chain, :message

  alias PolicrMini.Instances
  alias PolicrMini.Instances.Chat
  alias Telegex.Type.Message

  require Logger

  # 忽略 `new_chat_photo` 为空。
  @impl true
  def match?(%{new_chat_photo: nil} = _message, _context), do: false

  # 其余皆匹配。
  @impl true
  def match?(_message, _context), do: true

  @impl true
  def handle(%{chat: tg_chat} = message, context) do
    Logger.debug("New chat photo", chat_id: tg_chat.id)

    # 获取照片中的小图和大图，并更新相关字段。
    case Chat.get(tg_chat.id) do
      {:ok, chat} ->
        Instances.update_chat(chat, %{
          small_photo_id: small_photo_id(message),
          big_photo_id: big_photo_id(message)
        })

        {:ok, context}

      {:error, :not_found, _} ->
        Logger.warning(
          "New non-persistent chat: #{inspect(occurs_in: :new_chat_photo)}",
          chat_id: tg_chat.id
        )

        {:ok, context}
    end
  end

  # 从消息中获取小尺寸头像的文件 id。
  @spec small_photo_id(Message.t()) :: String.t()
  defp small_photo_id(%{new_chat_photo: []}), do: nil
  defp small_photo_id(%{new_chat_photo: [photo | _]}), do: photo.file_id

  # 从消息中获取大尺寸头像的文件 id。
  @spec big_photo_id(Message.t()) :: String.t()
  defp big_photo_id(%{new_chat_photo: []}), do: nil
  defp big_photo_id(%{new_chat_photo: [_, _, photo]}), do: photo.file_id
end
