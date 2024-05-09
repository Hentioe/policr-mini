defmodule PolicrMiniBot.Helper do
  @moduledoc """
  机器人功能助手模块，提供和机器人实现相关的各种辅助函数。

  通过 `use PolicrMiniBot, plug: ...` 实现的插件会自动导入本模块的所有函数。
  """

  alias __MODULE__.{
    CheckRequiredPermissions
  }

  alias Telegex.Type.{
    ChatMember,
    ChatMemberOwner,
    ChatMemberAdministrator,
    ChatMemberRestricted,
    ChatMemberLeft,
    ChatMemberBanned
  }

  use TypedStruct

  require Logger

  @type tgerr :: {:error, Telegex.Type.error()}
  @type tgmsg :: Telegex.Type.Message.t()

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

  @default_restrict_permissions %Telegex.Type.ChatPermissions{
    can_send_messages: false,
    can_send_audios: false,
    can_send_documents: false,
    can_send_photos: false,
    can_send_videos: false,
    can_send_video_notes: false,
    can_send_voice_notes: false,
    can_send_polls: false,
    can_send_other_messages: false,
    can_add_web_page_previews: false
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
    - `can_send_messages`: false,
    - `can_send_audios`: false,
    - `can_send_documents`: false,
    - `can_send_photos`: false,
    - `can_send_videos`: false,
    - `can_send_video_notes`: false,
    - `can_send_voice_notes`: false,
    - `can_send_polls`: false,
    - `can_send_other_messages`: false,
    - `can_add_web_page_previews`: false
  """
  def restrict_chat_member(chat_id, user_id) do
    Telegex.restrict_chat_member(chat_id, user_id, @default_restrict_permissions)
  end

  @doc """
  解除聊天成员限制。

  此调用会解除成员所有限制。根据 https://github.com/Hentioe/policr-mini/issues/126 中的测试，开放所有权限是安全的。
  """
  def derestrict_chat_member(chat_id, user_id) do
    Telegex.restrict_chat_member(chat_id, user_id, %Telegex.Type.ChatPermissions{
      can_send_messages: true,
      can_send_audios: true,
      can_send_documents: true,
      can_send_photos: true,
      can_send_videos: true,
      can_send_video_notes: true,
      can_send_voice_notes: true,
      can_send_polls: true,
      can_send_other_messages: true,
      can_add_web_page_previews: true
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
      |> Keyword.put_new(:parse_mode, "MarkdownV2")
      |> Keyword.put_new(:anonymization, false)
      |> Keyword.put_new(:mosaic, false)

    parse_mode = options[:parse_mode]

    name =
      if options[:anonymization] do
        to_string(id)
      else
        name = fullname(user)

        if options[:mosaic] do
          # 马赛克函数由于包含必要标签，会自行处理字符转义。
          mosaic_name(name, parse_mode)
        else
          safe_parse_mode(name, parse_mode)
        end
      end

    case parse_mode do
      "MarkdownV2" -> "[#{name}](tg://user?id=#{id})"
      "HTML" -> ~s(<a href="tg://user?id=#{id}">#{name}</a>)
    end
  end

  def safe_parse_mode(text, "MarkdownV2") do
    Telegex.Tools.safe_markdown(text)
  end

  def safe_parse_mode(text, "HTML") do
    Telegex.Tools.safe_html(text)
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
      iex>PolicrMiniBot.Helper.scheme_mention(%{id: 101, first_name: "Michael", last_name: "Jackson"}, :full_name)
      "[Michael Jackson](tg://user?id=101)"
      iex>PolicrMiniBot.Helper.scheme_mention(%{id: 101, first_name: "小红在上海鬼混", last_name: nil}, :mosaic_full_name)
      "[小||红在上海鬼||混](tg://user?id=101)"
  """
  @spec scheme_mention(mention_user, mention_scheme) :: String.t()
  def scheme_mention(user, scheme) do
    id = user[:id]

    display_text =
      case scheme do
        :user_id -> to_string(id)
        :full_name -> user |> fullname() |> Telegex.Tools.safe_markdown()
        :mosaic_full_name -> user |> fullname() |> mosaic_name("MarkdownV2")
      end

    "[#{display_text}](tg://user?id=#{id})"
  end

  typedstruct module: MosaicConfig do
    field :len, non_neg_integer
    field :parse_mode, String.t()
    field :method, :spoiler | :classic
  end

  @doc """
  构造马赛克名称。

  ## 例子
      iex> PolicrMiniBot.Helper.mosaic_name("小明", "MarkdownV2")
      "小||明||"
      iex> PolicrMiniBot.Helper.mosaic_name("Hello", "MarkdownV2")
      "H||ell||o"
      iex> PolicrMiniBot.Helper.mosaic_name("Hentioe", "MarkdownV2")
      "H||entio||e"

  """
  @spec mosaic_name(String.t(), String.t()) :: String.t()
  def mosaic_name(name, parse_mode) do
    _mosaic_name(name, %MosaicConfig{
      len: String.length(name),
      parse_mode: parse_mode,
      method: PolicrMiniBot.config_get(:mosaic_method, :spoiler)
    })
  end

  @spec _mosaic_name(String.t(), MosaicConfig.t()) :: String.t()

  # 只有一个字符的名称，不打马赛克。
  defp _mosaic_name(name, %{len: 1} = config) do
    case config.parse_mode do
      "MarkdownV2" -> Telegex.Tools.safe_markdown(name)
      "HTML" -> Telegex.Tools.safe_html(name)
    end
  end

  # 两个字符的名称，遮挡第二个字符（经典）。
  defp _mosaic_name(name, %{len: 2, method: :classic} = _config) do
    String.slice(name, 0..0) <> "░"
  end

  # 两个字符的名称，遮挡第二个字符（Spoiler）。
  defp _mosaic_name(name, %{len: 2, method: :spoiler, parse_mode: parse_mode}) do
    safe_parse_mode(String.slice(name, 0..0), parse_mode) <>
      wrap_spoiler(String.slice(name, 1..1), parse_mode)
  end

  # 3-5 个字符，遮挡除首尾外的中间字符（经典）。
  defp _mosaic_name(name, %{len: len, method: :classic}) when len >= 3 and len <= 5 do
    String.slice(name, 0..0) <> String.duplicate("░", len - 2) <> String.slice(name, -1..-1//1)
  end

  # 3-5 个字符，遮挡除首尾外的中间字符（Spoiler）。
  defp _mosaic_name(name, %{len: len, method: :spoiler, parse_mode: parse_mode})
       when len >= 3 and len <= 5 do
    last = len - 1

    safe_parse_mode(String.slice(name, 0..0), parse_mode) <>
      wrap_spoiler(String.slice(name, 1..(last - 1)), parse_mode) <>
      safe_parse_mode(String.slice(name, last..last), parse_mode)
  end

  defp _mosaic_name(name, %{method: :classic}) do
    "#{String.slice(name, 0..0)}███#{String.slice(name, -1..-1//1)}"
  end

  defp _mosaic_name(name, %{len: len, method: :spoiler, parse_mode: parse_mode}) do
    last = len - 1

    safe_parse_mode(String.slice(name, 0..0), parse_mode) <>
      wrap_spoiler(String.slice(name, 1..(last - 1)), parse_mode) <>
      safe_parse_mode(String.slice(name, last..last), parse_mode)
  end

  @doc """
  根据 `parse_mode` 包装 Spoiler 标签。
  """
  @spec wrap_spoiler(String.t(), String.t()) :: String.t()

  def wrap_spoiler(text, "MarkdownV2") do
    "||#{Telegex.Tools.safe_markdown(text)}||"
  end

  def wrap_spoiler(text, "HTML") do
    "<tg-spoiler>#{Telegex.Tools.safe_html(text)}</tg-spoiler>"
  end

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
      :grid
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
  @spec answer_callback_query(String.t(), keyword()) :: :ok | {:error, Telegex.Type.error()}
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

  # TODO: 为下列检查 `ChatMember` 的系列函数添加测试。
  @doc """
  检查 `ChatMember` 是否具有发言权限。
  """
  @spec can_send_messages?(ChatMember.t()) :: boolean

  # 权限受限，检查 `can_send_messages` 字段。
  def can_send_messages?(chat_member) when is_struct(chat_member, ChatMemberRestricted) do
    chat_member.can_send_messages
  end

  # 已离开或被封禁，直接返回 `false`。
  def can_send_messages?(chat_member)
      when is_struct(chat_member, ChatMemberLeft) or is_struct(chat_member, ChatMemberBanned) do
    false
  end

  # 其余情况，一律返回 `true`。
  def can_send_messages?(_chat_member) do
    true
  end

  @doc """
  检查 `ChatMember` 是否是管理员（包括所有者）。
  """
  @spec is_administrator?(Telegex.Type.ChatMember.t()) :: boolean

  # 是管理员或所有者，直接返回 `true`。
  def is_administrator?(chat_member)
      when is_struct(chat_member, ChatMemberAdministrator) or
             is_struct(chat_member, ChatMemberOwner) do
    true
  end

  # 其余情况，一律返回 `false`。
  def is_administrator?(_chat_member) do
    false
  end

  @doc """
  检查 `ChatMember` 是否能够删除消息。
  """
  @spec can_delete_messages?(Telegex.Type.ChatMember.t()) :: boolean

  # 是管理员，检查 `can_delete_messages` 字段。
  def can_delete_messages?(chat_member) when is_struct(chat_member, ChatMemberAdministrator) do
    chat_member.can_delete_messages
  end

  # 是所有者，直接返回 `true`。
  def can_delete_messages?(chat_member) when is_struct(chat_member, ChatMemberOwner) do
    true
  end

  # 其余情况，一律返回 `false`。
  def can_delete_messages?(_chat_member) do
    false
  end

  @doc """
  检查 `ChatMember` 是否能够限制成员权限。
  """
  @spec can_restrict_members?(Telegex.Type.ChatMember.t()) :: boolean

  # 是管理员，检查 `can_restrict_members` 字段。
  def can_restrict_members?(chat_member) when is_struct(chat_member, ChatMemberAdministrator) do
    chat_member.can_restrict_members
  end

  # 是所有者，直接返回 `true`。
  def can_restrict_members?(chat_member) when is_struct(chat_member, ChatMemberOwner) do
    true
  end

  # 其余情况，一律返回 `false`。
  def can_restrict_members?(_chat_member) do
    false
  end

  @doc """
  检查 `ChatMember` 是否能够提升成员。
  """
  @spec can_promote_members?(Telegex.Type.ChatMember.t()) :: boolean

  # 是管理员，检查 `can_promote_members` 字段。
  def can_promote_members?(chat_member) when is_struct(chat_member, ChatMemberAdministrator) do
    chat_member.can_promote_members
  end

  # 是所有者，直接返回 `true`。
  def can_promote_members?(chat_member) when is_struct(chat_member, ChatMemberOwner) do
    true
  end

  # 其余情况，一律返回 `false`。
  def can_promote_members?(_chat_member) do
    false
  end

  @spec async_delete_message(integer, integer) :: {:error, any()} | {:ok, Honeycomb.Bee.t()}
  def async_delete_message(chat_id, message_id) do
    run = {__MODULE__, :delete_message!, [chat_id, message_id]}

    Honeycomb.brew_honey(:cleaner, "delete-#{chat_id}-#{message_id}", run, stateless: true)
  end

  @spec async_delete_message_after(integer, integer, integer) ::
          {:error, any()} | {:ok, Honeycomb.Bee.t()}
  def async_delete_message_after(chat_id, message_id, second) do
    run = {__MODULE__, :delete_message!, [chat_id, message_id]}

    Honeycomb.brew_honey_after(:cleaner, "delete-#{chat_id}-#{message_id}", run, second * 1000,
      stateless: true
    )
  end

  @spec delete_message!(integer, integer) :: {:ok, true}
  def delete_message!(chat_id, message_id) do
    {:ok, true} = Telegex.delete_message(chat_id, message_id)
  end
end
