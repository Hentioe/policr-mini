defmodule PolicrMiniBot.HandlePrivateAttachmentChain do
  @moduledoc """
  处理私聊附件。

  ## 以下情况皆不匹配
    - 非私聊消息。
    - 消息不包含图片、文件、视频、音频。
  """

  use PolicrMiniBot.Chain, :message

  alias Telegex.Type.ReplyParameters

  # 忽略非私聊。
  @impl true
  def match?(%{chat: %{type: chat_type}} = _message, _context) when chat_type != "private" do
    false
  end

  # 忽略不包含附件。
  # 此处的 `photo` 字段可能为 `nil` 或空数组。
  @impl true
  def match?(%{photo: photo, document: document, video: video, audio: audio} = _message, _context)
      when (photo == nil or photo == []) and document == nil and video == nil and audio == nil do
    false
  end

  # 其余皆匹配。
  @impl true
  def match?(_message, _context), do: true

  @max_size_hint 25 * 1024

  @impl true
  def handle(message, context) do
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

           高度: <code>#{photo_size.height} px</code>
           宽度: <code>#{photo_size.width} px</code>
           大小: <code>#{bytes_to_kb(photo_size.file_size)} kb</code>
           """, photo_size.file_size}

        document ->
          {"""
           附件字符串:

           <code>document/#{document.file_id}</code>

           名称: <code>#{document.file_name}</code>
           大小: <code>#{bytes_to_kb(document.file_size)} kb</code>
           """, document.file_size}

        video ->
          {"""
           附件字符串:

           <code>video/#{video.file_id}</code>

           格式: <code>#{video.mime_type}</code>
           高度: <code>#{video.height} px</code>
           宽度: <code>#{video.width} px</code>
           大小: <code>#{bytes_to_kb(video.file_size)} kb</code>
           """, video.file_size}

        audio ->
          {"""
           附件字符串:

           <code>audio/#{audio.file_id}</code>

           格式: <code>#{audio.mime_type}</code>
           大小: <code>#{bytes_to_kb(audio.file_size)} kb</code>
           """, audio.file_size}
      end

    text = text <> "\n<i>用法提示：请直接将附件字符串复制到控制台相对应的编辑框中。</i>"

    text =
      if file_size > @max_size_hint do
        text <> "\n\n<b>注意：附件过大，会拖慢用户验证的速度。请尽量避免使用大文件，图片可采取压缩后再使用。</b>"
      else
        text
      end

    # TODO: `reply_parameters` 参数暂时无效，待 Telegex 项目单独测试。
    Telegex.send_message(chat_id, text,
      reply_parameters: %ReplyParameters{message_id: message_id},
      parse_mode: "HTML"
    )

    {:ok, context}
  end

  defp bytes_to_kb(bytes) do
    bytes |> Decimal.div(1024) |> Decimal.to_float() |> Float.round(2)
  end
end
