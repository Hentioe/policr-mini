defmodule PolicrMiniBot.HandleUserJoinedCleanupPlug do
  @moduledoc """
  处理新用户加入。
  """

  # TODO: 修改模块含义并迁移代码。因为设计改动，此 `:message_handler` 已无实际验证处理流程，仅作删除消息之用。

  use PolicrMiniBot, plug: :message_handler

  alias PolicrMini.Chats
  alias PolicrMini.Chats.Scheme
  alias PolicrMiniBot.Worker

  require Logger

  @type user :: PolicrMiniBot.Helper.mention_user()

  @doc """
  检查消息中包含的新加入用户是否有效。

  ## 以下情况皆不匹配
  - 群组未接管。

  除此之外包含新成员的消息都将匹配。
  """
  @impl true
  def match(_message, %{takeovered: false} = state), do: {:nomatch, state}
  @impl true
  def match(%{new_chat_members: nil} = _message, state), do: {:nomatch, state}
  @impl true
  def match(_message, state), do: {:match, state}

  @doc """
  删除进群服务消息。
  """
  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}} = message

    # TOD0: 将 scheme 的获取放在一个独立的 plug 中，通过状态传递。
    case Chats.fetch_scheme(chat_id) do
      {:ok, scheme} ->
        service_message_cleanup = scheme.service_message_cleanup || default!(:smc) || []

        if Enum.member?(service_message_cleanup, :joined) do
          # 删除服务消息。
          Worker.async_delete_message(chat_id, message.message_id)
        end
    end

    {:ok, %{state | done: true, deleted: true}}
  end

  @doc """
  生成验证入口消息内容。
  """
  @spec make_message_content(
          integer | binary,
          user,
          integer,
          Scheme.t(),
          integer
        ) ::
          {String.t(), InlineKeyboardMarkup.t()}

  @deprecated "Use `PolicrMiniBot.VerificationHelper.send_entrance_message/2` instead."
  def make_message_content(chat_id, user, waiting_count, scheme, seconds)
      when is_struct(scheme, Scheme) do
    # 读取等待验证的人数并根据人数分别响应不同的文本内容
    mention_scheme = scheme.mention_text || default!(:mention_scheme)

    text =
      if waiting_count == 1,
        do:
          t("verification.unity.single_waiting", %{
            mentioned_user: build_mention(user, mention_scheme),
            seconds: seconds
          }),
        else:
          t("verification.unity.multiple_waiting", %{
            mentioned_user: build_mention(user, mention_scheme),
            remaining_count: waiting_count - 1,
            seconds: seconds
          })

    markup = %InlineKeyboardMarkup{
      inline_keyboard: [
        [
          %InlineKeyboardButton{
            text: t("buttons.verification.click_here"),
            url: "https://t.me/#{bot_username()}?start=verification_v1_#{chat_id}"
          }
        ]
      ]
    }

    {text, markup}
  end
end
