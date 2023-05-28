defmodule PolicrMiniBot.MessageCaller do
  @moduledoc false

  # TODO: 增加超时重试机制

  @type tgerr :: Telegex.Model.errors()
  @type tgmsg :: Telegex.Model.Message.t()
  @type call_opts :: [
          caption: String.t(),
          parse_mode: String.t(),
          disable_notification: boolean,
          disable_web_page_preview: boolean,
          reply_to_message_id: integer,
          reply_markup: Telegex.Model.InlineKeyboardMarkup.t(),
          logging: boolean
        ]
  @type call_result :: {:ok, tgmsg} | {:error, tgerr}
  @type sender :: (integer | binary, call_opts -> call_result)
  @type editor :: (integer | binary, integer | binary, call_opts -> call_result)
  @type caller :: sender | editor

  use PolicrMini.I18n

  require Logger

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
      import unquote(__MODULE__), except: [call: 3]
    end
  end

  @spec call(caller, integer | binary, call_opts) :: call_result
  def call(caller, chat_id, opts \\ []) when is_function(caller) do
    {logging, opts} = Keyword.pop(opts, :logging, false)

    r = caller.(chat_id, opts)

    if logging && match?({:error, _}, r) do
      Logger.error("Send or edit message failed: #{inspect(reason: elem(r, 1))}", chat_id: chat_id)
    end

    r
  end

  @spec send_attachment(integer | binary, binary, call_opts) :: {:ok, tgmsg} | {:error, tgerr}
  def send_attachment(chat_id, attachment, opts \\ []) do
    sender = make_attachment_sender(attachment)

    call(sender, chat_id, opts)
  end

  @spec send_text(integer | binary, String.t(), call_opts) :: {:ok, tgmsg} | {:error, tgerr}
  def send_text(chat_id, text, opts \\ []) do
    sender = make_text_sender(text)

    call(sender, chat_id, opts)
  end

  def make_text_sender(text) do
    fn chat_id, optional ->
      Telegex.send_message(chat_id, text, optional)
    end
  end

  def make_text_editor(text, message_id) do
    fn chat_id, optional ->
      optional =
        optional
        |> Keyword.put(:chat_id, chat_id)
        |> Keyword.put(:message_id, message_id)

      Telegex.edit_message_text(text, optional)
    end
  end

  def make_attachment_sender(<<"photo/" <> file_id>> = _attachment) do
    fn chat_id, optional ->
      Telegex.send_photo(chat_id, file_id, optional)
    end
  end

  def make_attachment_sender(<<"video/" <> file_id>> = _attachment) do
    fn chat_id, optional ->
      Telegex.send_video(chat_id, file_id, optional)
    end
  end

  def make_attachment_sender(<<"audio/" <> file_id>> = _attachment) do
    fn chat_id, optional ->
      Telegex.send_video(chat_id, file_id, optional)
    end
  end

  def make_attachment_sender(<<"document/" <> file_id>> = _attachment) do
    fn chat_id, optional ->
      Telegex.send_document(chat_id, file_id, optional)
    end
  end

  def make_attachment_sender(_attachment) do
    fn chat_id, optional ->
      Telegex.send_message(chat_id, commands_text("这是一条错误：消息生成失败，不受支持的附件类型或无效的附件字符串。"), optional)
    end
  end
end
