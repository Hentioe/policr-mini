defmodule PolicrMiniBot.MessageCaller do
  @moduledoc false

  # TODO: 增加超时重试机制

  use PolicrMini.I18n
  use TypedStruct

  require Logger

  @type tgerr :: Telegex.Type.error()
  @type tgmsg :: Telegex.Type.Message.t()
  @type call_opts :: [
          caption: String.t(),
          parse_mode: String.t(),
          disable_notification: boolean,
          disable_web_page_preview: boolean,
          reply_to_message_id: integer,
          reply_markup: Telegex.Type.InlineKeyboardMarkup.t(),
          logging: boolean
        ]
  @type call_result :: {:ok, tgmsg} | {:error, tgerr}

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
      import unquote(__MODULE__), except: [call: 3]
    end
  end

  defmodule Sender do
    @moduledoc false

    typedstruct do
      field :text, String.t()
      field :attachment, String.t()
    end

    # 作为图片消息发送
    def call(%{attachment: <<"photo/" <> file_id>>} = _sender, chat_id, optional) do
      Telegex.send_photo(chat_id, file_id, optional)
    end

    # 作为视频消息发送
    def call(%{attachment: <<"video/" <> file_id>>} = _sender, chat_id, optional) do
      Telegex.send_video(chat_id, file_id, optional)
    end

    # 作为音频消息发送
    def call(%{attachment: <<"audio/" <> file_id>>} = _sender, chat_id, optional) do
      Telegex.send_audio(chat_id, file_id, optional)
    end

    # 作为文件消息发送
    def call(%{attachment: <<"document/" <> file_id>>} = _sender, chat_id, optional) do
      Telegex.send_document(chat_id, file_id, optional)
    end

    # 作为错误消息发送：未知的附件类型
    def call(%{attachment: attachment} = _sender, chat_id, optional) when attachment != nil do
      Telegex.send_message(chat_id, commands_text("这是一条错误：消息生成失败，不受支持的附件类型或无效的附件字符串。"), optional)
    end

    # 作为普通文本消息发送
    def call(%{text: text} = _sender, chat_id, optional) when text != nil do
      Telegex.send_message(chat_id, text, optional)
    end
  end

  defmodule Editor do
    @moduledoc false

    typedstruct do
      field :text, String.t(), enforce: true
      field :message_id, integer, enforce: true

      def call(%{text: text, message_id: message_id} = _editor, chat_id, optional) do
        optional =
          optional
          |> Keyword.put(:chat_id, chat_id)
          |> Keyword.put(:message_id, message_id)

        Telegex.edit_message_text(text, optional)
      end
    end
  end

  @type caller :: Sender.t() | Editor.t()

  @doc """
  调用 sender 或 editor 处理消息。

  **注意：此函数并不会对 `opts` 参数做任何处理，即没有默认选项。**
  """
  @spec call(caller, integer | binary, call_opts) :: call_result
  def call(caller, chat_id, opts \\ []) do
    _call(caller, chat_id, opts)
  end

  def _call(caller, chat_id, opts) when is_struct(caller, Sender) do
    {logging, opts} = Keyword.pop(opts, :logging, false)

    r = Sender.call(caller, chat_id, opts)

    if logging && match?({:error, _}, r) do
      Logger.error("Send message failed: #{inspect(text: caller.text, reason: elem(r, 1))}",
        chat_id: chat_id
      )
    end

    r
  end

  def _call(caller, chat_id, opts) when is_struct(caller, Editor) do
    {logging, opts} = Keyword.pop(opts, :logging, false)

    r = Editor.call(caller, chat_id, opts)

    if logging && match?({:error, _}, r) do
      Logger.error(
        "Edit message failed: #{inspect(text: caller.text, message_id: caller.message_id, reason: elem(r, 1))}",
        chat_id: chat_id
      )
    end

    r
  end

  @spec send_attachment(integer | binary, binary, call_opts) :: {:ok, tgmsg} | {:error, tgerr}
  def send_attachment(chat_id, attachment, opts \\ []) do
    sender = attachment_sender(attachment)

    opts =
      opts
      |> Keyword.put_new(:disable_notification, true)
      |> Keyword.put_new(:disable_web_page_preview, true)

    sender =
      if caption = Keyword.get(opts, :caption) do
        %{sender | text: caption}
      else
        sender
      end

    call(sender, chat_id, opts)
  end

  @spec send_text(integer | binary, String.t(), call_opts) :: {:ok, tgmsg} | {:error, tgerr}
  def send_text(chat_id, text, opts \\ []) do
    sender = text_sender(text)

    opts =
      opts
      |> Keyword.put_new(:disable_notification, true)
      |> Keyword.put_new(:disable_web_page_preview, true)

    call(sender, chat_id, opts)
  end

  @spec edit_text(integer | binary, integer | binary, String.t(), call_opts) ::
          {:ok, tgmsg} | {:error, tgerr}
  def edit_text(chat_id, message_id, text, opts \\ []) do
    editor = text_editor(text, message_id)

    opts = Keyword.put_new(opts, :disable_web_page_preview, true)

    call(editor, chat_id, opts)
  end

  def text_sender(text) do
    %Sender{text: text}
  end

  def attachment_sender(attachment) do
    %Sender{attachment: attachment}
  end

  def text_editor(text, message_id) do
    %Editor{text: text, message_id: message_id}
  end
end
