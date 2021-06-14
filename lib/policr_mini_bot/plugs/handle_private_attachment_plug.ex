defmodule PolicrMiniBot.HandlePrivateAttachmentPlug do
  @moduledoc false

  use PolicrMiniBot, plug: :message_handler

  @impl true
  def match(%{chat: %{type: type}} = _message, state)
      when type in ["channel", "group", "supergroup"] do
    {:nomatch, state}
  end

  @impl true
  def match(%{photo: photo, document: document, video: video, audio: audio} = _message, state)
      when (photo == nil or photo == []) and document == nil and video == nil and audio == nil do
    {:nomatch, state}
  end

  @impl true
  def match(_message, state), do: {:match, state}

  @max_size_hint 15 * 1024

  @impl true
  def handle(message, state) do
    %{
      chat: %{id: chat_id},
      message_id: message_id,
      photo: photo,
      document: document,
      video: video,
      audio: audio
    } = message

    {text, file_size} =
      cond do
        photo != nil && length(photo) > 0 ->
          photo_size = List.last(photo)

          {"""
           附件字符串:

           <code>photo/#{photo_size.file_id}</code>

           高度: <code>#{photo_size.height}</code> px
           宽度: <code>#{photo_size.width}</code> px
           大小: <code>#{photo_size.file_size}</code> bytes
           """, photo_size.file_size}

        document ->
          {"""
           附件字符串:

           <code>document/#{document.file_id}</code>

           名称: <code>#{document.file_name}</code>
           大小: <code>#{document.file_size}</code> bytes
           """, document.file_size}

        video ->
          {"""
           附件字符串:

           <code>video/#{video.file_id}</code>

           格式: <code>#{video.mime_type}</code>
           高度: <code>#{video.height}</code> px
           宽度: <code>#{video.width}</code> px
           大小: <code>#{video.file_size}</code> bytes
           """, video.file_size}

        audio ->
          {"""
           附件字符串:

           <code>audio/#{audio.file_id}</code>

           格式: <code>#{audio.mime_type}</code>
           大小: <code>#{audio.file_size}</code> bytes
           """, audio.file_size}
      end

    text =
      text <>
        "\n<i>用法提示：请直接将附件字符串复制到后台相对应的编辑框中。</i>"

    text =
      if file_size > @max_size_hint do
        text <> "\n\n<b>注意：附件过大，会拖慢用户验证的速度。请不要使用大文件，图片可采取压缩后再使用。</b>"
      else
        text
      end

    Telegex.send_message(chat_id, text, reply_to_message_id: message_id, parse_mode: "HTML")

    {:ok, state}
  end
end
