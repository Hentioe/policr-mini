defmodule PolicrMini.Bot.Helper do
  @moduledoc """
  机器人相关功能的助手模块，提供各种和机器人实现相关的各种便捷函数。
  被 `PolicrMini.Bot.Handler`/`PolicrMini.Bot.Commander` 模块默认导入。
  """

  alias PolicrMini.ChatBusiness

  @doc """
  获取机器人自身的 `id` 字段。详情参照 `PolicrMini.Bot.id/0` 函数。
  """
  defdelegate bot_id(), to: PolicrMini.Bot, as: :id

  @doc """
  获取机器人自身的 `username` 字段。详情参照 `PolicrMini.Bot.username/0` 函数。
  """
  defdelegate bot_username(), to: PolicrMini.Bot, as: :username

  @doc """
  通过同时包含 `first_name` 和 `last_name` 字段的 map 数据构造全名。
  """
  def fullname(%{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"

  @doc """
  通过仅包含 `first_name` 字段的 map 数据构造全名。
  """
  def fullname(%{first_name: first_name}), do: first_name

  @doc """
  通过仅包含 `last_name` 字段的 map 数据构造全名。
  """
  def fullname(%{last_name: last_name}), do: last_name

  @doc """
  通过包含 `fullname` 字段的 map 数据构造全名。
  """
  def fullname(%{fullname: fullname}), do: fullname

  @doc """
  通过进包含 `id` 字段的 map 数据构造全名。
  """
  def fullname(%{id: id}), do: Integer.to_string(id)

  @doc """
  发送文本消息。
  如果 `options` 参数中不包含 `:disable_notification` 或 `:parse_mode` 配置，将为它们准备以下默认值：
  - `disable_notification`: `true`
  - `parse_mode`: `"Markdown"`
  """
  def send_message(chat_id, text, options \\ []) do
    options =
      options
      |> Keyword.put_new(:disable_notification, true)
      |> Keyword.put_new(:parse_mode, "Markdown")

    Nadia.send_message(chat_id, text, options)
  end

  @doc """
  回复文本消息。
  其 `message_id` 参数的值会合并到 `options` 参数中的 `reply_to_message_id` 配置中。其余请参考 `send_message/3`
  """
  def reply_message(chat_id, message_id, text, options \\ []) do
    options = options |> Keyword.merge(reply_to_message_id: message_id)
    send_message(chat_id, text, options)
  end

  @default_restrict_permissions %Nadia.Model.ChatPermissions{
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
    Nadia.restrict_chat_member(chat_id, user_id, @default_restrict_permissions)
  end

  @doc """
  解除聊天成员限制。
  此调用产生的权限修改是动态的，它会将被限制用户的权限恢复为群组记录中的原始权限配置。
  """
  def derestrict_chat_member(chat_id, user_id) do
    {:ok,
     %{
       tg_can_send_messages: can_send_messages,
       tg_can_send_media_messages: can_send_media_messages,
       tg_can_send_polls: can_send_polls,
       tg_can_send_other_messages: can_send_other_messages,
       tg_can_add_web_page_previews: can_add_web_page_previews,
       tg_can_change_info: can_change_info,
       tg_can_invite_users: can_invite_users,
       tg_can_pin_messages: can_pin_messages
     }} = ChatBusiness.get(chat_id)

    Nadia.restrict_chat_member(chat_id, user_id, %Nadia.Model.ChatPermissions{
      can_send_messages: can_send_messages,
      can_send_media_messages: can_send_media_messages,
      can_send_polls: can_send_polls,
      can_send_other_messages: can_send_other_messages,
      can_add_web_page_previews: can_add_web_page_previews,
      can_change_info: can_change_info,
      can_invite_users: can_invite_users,
      can_pin_messages: can_pin_messages
    })
  end

  @doc """
  生成提及用户的文本内容。
  参数 `user` 需要满足 `fullname/1` 函数子句的任意条件，同时必须包含 `id` 字段。
  参数 `parse_mode` 默认值为 `"MarkdownV2"`，可配置为 `"HTML"`。
  注意 `parse_mode` 需要跟 `send_message/3` 中的配置一致，否则最终的消息形式不正确，并且无法对被提及用户产生通知。
  """
  def at(user, parse_mode \\ "MarkdownV2") when is_map(user) do
    case parse_mode do
      "MarkdownV2" -> "[#{fullname(user)}](tg://user?id=#{user.id})"
      "HTML" -> ~s(<a href="tg://user?id=#{user.id}">#{fullname(user)}</a>)
    end
  end

  @doc """
  异步执行函数，不指定延迟时间。
  """
  def async(callback) when is_function(callback), do: TaskAfter.task_after(0, callback)

  @doc """
  异步执行函数，可指定单位为秒的延迟时间。

  iex> PolicrMini.Bot.Helper.async(fn -> IO.puts("Hello") end, seconds: 3)
  """
  def async(callback, [{:seconds, seconds}]) when is_integer(seconds) and is_function(callback),
    do: TaskAfter.task_after(seconds * 1000, callback)
end
