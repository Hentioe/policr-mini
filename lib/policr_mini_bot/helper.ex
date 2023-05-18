defmodule PolicrMiniBot.Helper do
  @moduledoc """
  机器人功能助手模块，提供和机器人实现相关的各种辅助函数。

  通过 `use PolicrMiniBot, plug: ...` 实现的插件会自动导入本模块的所有函数。
  """

  alias __MODULE__.{
    CheckRequiredPermissions,
    Sender
  }

  alias Telegex.Model.ChatMember

  require Logger

  @type tgerr :: {:error, Telegex.Model.errors()}
  @type tgmsg :: Telegex.Model.Message.t()

  @doc """
  获取机器人自身的 `id` 字段。详情参照 `PolicrMiniBot.id/0` 函数。
  """
  defdelegate bot_id, to: PolicrMiniBot, as: :id

  @doc """
  获取机器人自身的 `username` 字段。详情参照 `PolicrMiniBot.username/0` 函数。
  """
  defdelegate bot_username, to: PolicrMiniBot, as: :username

  @doc """
  根据 map 数据构造用户全名。

  如果 fist_name 和 last_name 都不存在，则使用 id。
  """
  @spec fullname(map()) :: String.t()
  def fullname(%{first_name: first_name, last_name: nil}),
    do: first_name

  def fullname(%{first_name: first_name, last_name: last_name}),
    do: "#{first_name} #{last_name}"

  def fullname(%{fullname: fullname}), do: fullname
  def fullname(%{id: id}), do: Integer.to_string(id)

  @doc """
  转义 Markdown 中不能被 Telegram 发送的字符。

  ## Examples
      iex> PolicrMiniBot.Helper.escape_markdown("'_', '*', '[', ']', '(', ')', '~', '`', '>', '#', '+', '-', '=', '|', '{', '}', '.', '!'")
      ~S"'\\_', '\\*', '\\[', '\\]', '\\(', '\\)', '\\~', '\\`', '\\>', '\\#', '\\+', '\\-', '\\=', '\\|', '\\{', '\\}', '\\.', '\\!'"
  """
  def escape_markdown(text) do
    String.replace(
      text,
      ~r/(\_|\*|\[|\]|\(|\)|\~|\`|\>|\#|\+|\-|\=|\||\{|\}|\.|\!)/,
      "\\\\\\g{1}"
    )
  end

  @spec escape_marked(binary) :: binary
  def escape_marked(text) do
    text
    |> String.replace(".", "\\.")
    |> String.replace("+", "\\+")
    |> String.replace("-", "\\-")
    |> String.replace("=", "\\=")
  end

  # 过滤掉关键字列表中的 nil 值
  defp delete_keyword_nils(keyword) when is_list(keyword) do
    keyword |> Enum.filter(fn {_, value} -> value != nil end)
  end

  @time_seeds [0.2, 0.4, 0.8, 1.0]
  @markdown_parse_mode "MarkdownV2"
  @markdown_to_html_parse_mode "MarkdownV2ToHTML"

  @type parsemode :: String.t()

  @type message_text :: String.t()
  @type send_message_opts :: [
          {:disable_notification, boolean},
          {:parse_mode, parsemode | nil},
          {:disable_web_page_preview, boolean},
          {:reply_markup, Telegex.Model.InlineKeyboardMarkup.t()},
          {:retry, integer},
          {:unescaped, boolean}
        ]

  @spec preprocess_send_message_args(message_text, send_message_opts) ::
          {message_text, send_message_opts}
  defp preprocess_send_message_args(text, options) do
    options =
      options
      |> Keyword.put_new(:disable_notification, true)
      |> Keyword.put_new(:parse_mode, @markdown_parse_mode)
      |> Keyword.put_new(:disable_web_page_preview, true)
      |> Keyword.put_new(:retry, 5)
      |> Keyword.put_new(:unescaped, false)
      |> delete_keyword_nils()

    parse_mode = Keyword.get(options, :parse_mode)
    unescaped = Keyword.get(options, :unescaped)

    case parse_mode do
      @markdown_parse_mode ->
        text = if unescaped, do: text, else: escape_marked(text)

        {text, options}

      @markdown_to_html_parse_mode ->
        text = Telegex.Marked.as_html(text)

        {text, Keyword.put(options, :parse_mode, "HTML")}

      _ ->
        {text, options}
    end
  end

  @doc """
  发送文本消息。

  参数 `options` 参考 `Telegex.send_message/3` 的 `optinal` 说明。除此之外，还有一些附加参数支持以及默认值。
  ## 附加可选参数和默认值
  - `disable_notification`: 默认值为 `true`。
  - `parse_mode`: 默认值为 `MarkdownV2`。
  - `disable_web_page_preview`: 默认值为 `false`。
  - `retry`: 附加参数，表示发送失败时自动重试的最大次数，默认值为 `5`。
  """
  @spec send_message(integer, String.t(), send_message_opts) :: {:ok, tgmsg} | tgerr()
  def send_message(chat_id, text, options \\ []) do
    {text, options} = preprocess_send_message_args(text, options)

    case Telegex.send_message(chat_id, text, options) do
      {:ok, message} ->
        {:ok, message}

      {:error, %Telegex.Model.RequestError{reason: :timeout}} = e ->
        # 处理重试（减少次数并递归）
        retry = options |> Keyword.get(:retry)

        if retry && retry > 0 do
          Logger.warning(
            "Send message timed out: #{inspect(remaining_times: retry - 1)}",
            chat_id: chat_id
          )

          options = options |> Keyword.put(:retry, retry - 1)
          send_message(chat_id, text, options)
        else
          e
        end

      {:error, %Telegex.Model.Error{description: <<"Too Many Requests: retry after">> <> _rest}} =
          e ->
        retry = options |> Keyword.get(:retry)

        if retry && retry > 0 do
          Logger.warning(
            "Message sending is limited due to the excessive number of requests: #{inspect(remaining_times: retry - 1)}",
            chat_id: chat_id
          )

          options = options |> Keyword.put(:retry, retry - 1)
          :timer.sleep(trunc(800 * retry * Enum.random(@time_seeds)))
          send_message(chat_id, text, options)
        else
          e
        end

      {:error, %{error_code: 403}} = e ->
        Logger.warning(
          "Send message failed due to user blocking",
          chat_id: chat_id
        )

        e

      {:error, reason} = e ->
        Logger.error("Send message failed: #{inspect(text: text, reason: reason)}",
          chat_id: chat_id
        )

        e
    end
  end

  @doc """
  编辑消息。

  如果 `options` 参数中不包含以下配置，将为它们准备默认值：
  - `parse_mode`: `"MarkdownV2"`
  - `disable_web_page_preview`: `false`
  """
  @spec edit_message_text(String.t(), keyword) :: {:ok, tgmsg} | tgerr
  def edit_message_text(text, options \\ []) do
    options =
      options
      |> Keyword.put_new(:parse_mode, @markdown_parse_mode)
      |> Keyword.put_new(:disable_web_page_preview, true)
      |> delete_keyword_nils()

    text =
      if(options |> Keyword.get(:parse_mode) == @markdown_parse_mode) do
        escape_marked(text)
      else
        text
      end

    Telegex.edit_message_text(text, options)
  end

  @doc """
  回复文本消息。
  其 `message_id` 参数的值会合并到 `options` 参数中的 `reply_to_message_id` 配置中。其余请参考 `send_message/3`
  """
  def reply_message(chat_id, message_id, text, options \\ []) do
    options = options |> Keyword.merge(reply_to_message_id: message_id)

    send_message(chat_id, text, options)
  end

  @default_restrict_permissions %Telegex.Model.ChatPermissions{
    can_send_messages: false,
    can_send_media_messages: false,
    can_send_polls: false,
    can_send_other_messages: false,
    can_add_web_page_previews: false,
    can_change_info: false,
    can_invite_users: false,
    can_pin_messages: false
  }

  @doc """
  删除消息。

  附加的 `options` 参数可配置 `delay_seconds` 实现延迟删除。
  注意，延迟删除无法直接获得请求结果，将直接返回 `:ok`。
  """
  @spec delete_message(integer, integer, [{atom, any}]) :: {:ok, true} | tgerr
  def delete_message(chat_id, message_id, options \\ []) do
    delay_seconds =
      options
      |> Keyword.get(:delay_seconds)

    if delay_seconds do
      delay_seconds = if delay_seconds < 0, do: 0, else: delay_seconds
      async_run(fn -> Telegex.delete_message(chat_id, message_id) end, delay_secs: delay_seconds)

      {:ok, true}
    else
      Telegex.delete_message(chat_id, message_id)
    end
  end

  @doc """
  限制聊天成员。

  目前来讲，它会限制以下权限：
  - `can_send_messages`: `false`
  - `can_send_media_messages`: `false`
  - `can_send_polls`: `false`
  - `can_send_other_messages`: `false`
  - `can_add_web_page_previews`: `false`
  - `can_change_info`: `false`
  - `can_invite_users`: `false`
  - `can_pin_messages`: `false`
  """
  def restrict_chat_member(chat_id, user_id) do
    Telegex.restrict_chat_member(chat_id, user_id, @default_restrict_permissions)
  end

  @doc """
  解除聊天成员限制。

  此调用会解除成员所有限制。根据 https://github.com/Hentioe/policr-mini/issues/126 中的测试，开放所有权限是安全的。
  """
  def derestrict_chat_member(chat_id, user_id) do
    Telegex.restrict_chat_member(chat_id, user_id, %Telegex.Model.ChatPermissions{
      can_send_messages: true,
      can_send_media_messages: true,
      can_send_polls: true,
      can_send_other_messages: true,
      can_add_web_page_previews: true,
      can_change_info: true,
      can_invite_users: true,
      can_pin_messages: true
    })
  end

  @doc """
  让机器人显示正常打字的动作。
  """
  @spec typing(integer) :: {:ok, boolean} | tgerr
  def typing(chat_id) do
    Telegex.send_chat_action(chat_id, "typing")
  end

  @type mention_opts :: [
          {:parse_mode, String.t()},
          {:anonymization, boolean()},
          {:mosaic, boolean()}
        ]
  @doc """
  生成提及用户的文本内容。

  参数 `user` 需要满足 `fullname/1` 函数子句的任意条件，同时必须包含 `id` 字段。
  参数 `options` 可包括以下选项：
  - `parse_mode` 默认值为 `"MarkdownV2"`，可配置为 `"HTML"`。
  - `anonymization` 默认值为 `true`，可配置为 `false`。

  注意：`parse_mode` 需要跟 `send_message/3` 中的配置一致，否则最终的消息形式不正确，并且无法对被提及用户产生通知。
  """
  @spec mention(map, mention_opts) :: String.t()
  def mention(%{id: id} = user, options \\ []) do
    options =
      options
      |> Keyword.put_new(:parse_mode, @markdown_parse_mode)
      |> Keyword.put_new(:anonymization, true)
      |> Keyword.put_new(:mosaic, false)

    name =
      if options[:anonymization] do
        to_string(id)
      else
        name = fullname(user)

        if options[:mosaic] do
          mosaic_name(name)
        else
          name
        end
      end

    case options[:parse_mode] do
      "MarkdownV2" -> "[#{escape_markdown(name)}](tg://user?id=#{id})"
      "HTML" -> ~s(<a href="tg://user?id=#{id}">#{Telegex.Tools.safe_html(name)}</a>)
    end
  end

  @type fullname_user :: %{
          :id => integer,
          :fullname => binary
        }
  @type raw_user :: %{
          :id => integer,
          :first_name => binary,
          :last_name => binary
        }

  @type mention_user :: raw_user | fullname_user
  @type mention_scheme :: :user_id | :full_name | :mosaic_full_name

  @doc """
  根据方案提及用户。

  请注意：此函数输出 `MarkdownV2` 格式，且不能定制。

  ## 例子
      iex>PolicrMiniBot.Helper.build_mention(%{id: 101, first_name: "Michael", last_name: "Jackson"}, :full_name)
      "[Michael Jackson](tg://user?id=101)"
      iex>PolicrMiniBot.Helper.build_mention(%{id: 101, first_name: "小红在上海鬼混", last_name: nil}, :mosaic_full_name)
      "[小███混](tg://user?id=101)"
  """
  @spec build_mention(mention_user, mention_scheme) :: String.t()
  def build_mention(user, scheme) do
    id = user[:id]

    text =
      case scheme do
        :user_id -> to_string(id)
        :full_name -> fullname(user)
        :mosaic_full_name -> user |> fullname() |> mosaic_name()
      end

    "[#{escape_markdown(text)}](tg://user?id=#{id})"
  end

  @doc """
  给名字打马赛克。

  将名字中的部分字符替换成 `░` 符号。如果名字过长（超过五个字符），则只保留前后两个字符，中间使用三个 `█` 填充。

  ## 例子
      iex> PolicrMiniBot.Helper.mosaic_name("小明")
      "小░"
      iex> PolicrMiniBot.Helper.mosaic_name("Hello")
      "H░░░o"
      iex> PolicrMiniBot.Helper.mosaic_name("Hentioe")
      "H███e"

  """
  @spec mosaic_name(String.t()) :: String.t()
  def mosaic_name(name), do: mosaic_name_by_len(name, String.length(name))

  @spec mosaic_name_by_len(String.t(), integer) :: String.t()
  defp mosaic_name_by_len(name, len) when is_integer(len) and len == 1 do
    name
  end

  defp mosaic_name_by_len(name, len) when is_integer(len) and len == 2 do
    name
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map_join(fn {char, index} ->
      if index == 1, do: "░", else: char
    end)
  end

  defp mosaic_name_by_len(name, len) when is_integer(len) and len >= 3 and len <= 5 do
    last_index = len - 1

    name
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map_join(fn {char, index} ->
      if index == 0 || index == last_index, do: char, else: "░"
    end)
  end

  defp mosaic_name_by_len(name, _len), do: "#{String.at(name, 0)}███#{String.at(name, -1)}"

  @defaults_key_mapping [
    vmode: :verification_mode,
    vseconds: :seconds,
    tkmethod: :timeout_killing_method,
    wkmethod: :wrong_killing_method,
    delay_unban_secs: :delay_unban_secs,
    mention_scheme: :mention_text,
    acimage: :image_answers_count,
    smc: :service_message_cleanup
  ]

  @type default_keys ::
          :vmode
          | :vseconds
          | :tkmethod
          | :wkmethod
          | :delay_unban_secs
          | :mention_scheme
          | :acimage
          | :smc

  @doc """
  获取默认配置。

  ## 当前 `key` 可以是以下值
  - `:vmode`: 验证方式。
  - `:vseconds`: 验证超时时间。
  - `:tkmethod`: 超时击杀方法。
  - `:wkmethod`: 错误击杀方法。
  - `:delay_unban_secs`: 延时解封秒数。
  - `:mention_scheme`: 提及方案。
  - `:smc`: 服务消息清理。

  ## 例子
      iex> PolicrMiniBot.Helper.default!(:vmode)
      :image
      iex> PolicrMiniBot.Helper.default!(:vseconds)
      300
      iex> PolicrMiniBot.Helper.default!(:tkmethod)
      :kick
      iex> PolicrMiniBot.Helper.default!(:wkmethod)
      :kick
      iex> PolicrMiniBot.Helper.default!(:delay_unban_secs)
      300
      iex> PolicrMiniBot.Helper.default!(:mention_scheme)
      :mosaic_full_name
      iex> PolicrMiniBot.Helper.default!(:acimage)
      4
      iex> PolicrMiniBot.Helper.default!(:smc)
      [:joined]
  """
  @spec default!(default_keys) :: any
  def default!(key) when is_atom(key) do
    field = @defaults_key_mapping[key] || raise "Default field name without key `#{key}` mapping"

    PolicrMini.DefaultsServer.get_scheme_value(field)
  end

  @spec t(String.t(), map()) :: String.t()
  @doc """
  使用默认 `locale` 搜索国际化翻译。
  """
  def t(key, values \\ %{}) do
    t(ExI18n.locale(), key, values)
  end

  @doc """
  搜索国际化翻译。

  参数 `locale` 为 `priv/locals` 中 `yml` 文件的名称。
  参数 `values` 用于给翻译字符串中的变量赋值。
  """
  @spec t(String.t(), String.t(), map()) :: String.t()
  def t(locale, key, values)
      when is_binary(locale) and is_binary(key) and is_map(values) do
    try do
      ExI18n.t(locale, key, values)
    rescue
      e ->
        Logger.error("Translation search failed: #{inspect(key: key, error: e)}")

        String.replace("#{locale}:#{key}", "_", "\\_")
    end
  end

  @spec async_run(function, delay_secs: integer) :: Honeydew.Job.t() | no_return
  defdelegate async_run(fun, opts \\ []), to: PolicrMini.Worker.GeneralRun, as: :async_run

  defmacro async({:fn, _, _} = lambda) do
    quote do
      PolicrMiniBot.Helper.async_run(unquote(lambda))
    end
  end

  defmacro async(do: block) do
    quote do
      PolicrMiniBot.Helper.async_run(fn -> unquote(block) end)
    end
  end

  @doc """
  响应回调查询。
  """
  @spec answer_callback_query(String.t(), keyword()) :: :ok | {:error, Telegex.Model.errors()}
  def answer_callback_query(callback_query_id, options \\ []) do
    Telegex.answer_callback_query(callback_query_id, options)
  end

  @doc """
  解析回调中的数据。
  """
  @spec parse_callback_data(String.t()) :: {String.t(), [String.t()]}
  def parse_callback_data(data) when is_binary(data) do
    [_, version | args] = data |> String.split(":")

    {version, args}
  end

  @doc """
  检查接管所需权限。当成员不是管理员时返回 `nonadm`，缺失的管理权限时返回 `{:missing, [permission]}` ，满足接管所需权限时 `:ok`。
  """
  @spec check_takeover_permissions(ChatMember.t()) ::
          {:missing, [CheckRequiredPermissions.permission()]}
          | :nonadm
          | :ok

  defdelegate check_takeover_permissions(member), to: CheckRequiredPermissions

  defdelegate send_attachment(chat_id, attachment, opts \\ []), to: Sender
  defdelegate send_text(chat_id, text, opts \\ []), to: Sender
end
