defmodule PolicrMiniBot.NewChatPhotoHandler do
  @moduledoc """
  新群组头像处理器。
  """

  use PolicrMiniBot, plug: :handler

  alias PolicrMini.ChatBusiness

  @doc """
  匹配消息是否包含群组头像修改。

  消息中的 `new_chat_photo` 为 `nil` 时，表示不匹配。否则匹配。
  """
  @impl true
  def match(%{new_chat_photo: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(_message, state), do: {:match, state}

  @doc """
  处理群组头像修改。

  更新数据库中对应的群组记录的头像数据。
  """
  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    # 获取照片中的小图和大图，并更新相应数据
    case ChatBusiness.get(chat_id) do
      {:ok, chat} ->
        ChatBusiness.update(chat, %{
          small_photo_id: small_photo_id(message),
          big_photo_id: big_photo_id(message)
        })

        {:ok, state}

      _ ->
        {:ok, state}
    end

    {:ok, state}
  end

  # 从消息中获取小尺寸头像的文件 id
  @spec small_photo_id(Message.t()) :: String.t()
  defp small_photo_id(%{new_chat_photo: []}), do: nil
  defp small_photo_id(%{new_chat_photo: [photo | _]}), do: photo.file_id

  # 从消息中获取大尺寸头像的文件 id
  @spec big_photo_id(Message.t()) :: String.t()
  defp big_photo_id(%{new_chat_photo: []}), do: nil
  defp big_photo_id(%{new_chat_photo: [_, _, photo]}), do: photo.file_id
end
