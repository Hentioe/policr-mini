defmodule PolicrMiniBot.NewChatPhotoHandler do
  @moduledoc """
  新群组头像处理器。
  """

  use PolicrMiniBot, plug: :handler

  # alias PolicrMini.ChatBusiness

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
  def handle(_message, state) do
    # TODO: 获取照片中的小图和大图，并更新相应数据
    {:ok, state}
  end
end
