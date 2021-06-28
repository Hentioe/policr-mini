defmodule PolicrMiniBot.RespSponsorshipCmdPlug do
  @moduledoc """
  /sponsorship 命令。
  """

  use PolicrMiniBot, plug: [commander: :sponsorship]

  alias PolicrMiniBot.SpeedLimiter

  @default_ttl 1000 * 60 * 10

  @impl true
  def handle(%{chat: %{type: "private"}} = message, state) do
    %{chat: %{id: chat_id}} = message

    speed_limit_key = "sponsorship-cmd-#{chat_id}"
    wainting_time = SpeedLimiter.get(speed_limit_key)

    if wainting_time == 0 do
      token = gen_and_cache_new_token(chat_id)

      web_root = PolicrMiniWeb.root_url(has_end_slash: true)

      text = """
      已生成一条赞助口令，使用它即可从 web 入口提交赞助表单。此口令可以多次使用，但会在 <u>10</u> 分钟后失效。

      <code>#{token}</code>

      从<a href="#{web_root}?sponsorship=#{token}">这里</a>直接打开赞助表单并自动填充此口令。

      <i>提示：赞助口令不会把您和表单中的赞助人关联上，但会保留创建关系。它是一种防御攻击的措施，除此之外没有任何实际意义。</i>
      """

      :ok = SpeedLimiter.put(speed_limit_key, 60 * 5)

      {:ok, _} = Telegex.send_message(chat_id, text, parse_mode: "HTML")
    else
      text = """
      <b>生成过于频繁，请在 #{wainting_time} 秒后重试。</b>

      <i>提示：多次使用相同的有效的口令没有任何区别，在失效前不必重复生成。</i>
      """

      {:ok, _} = Telegex.send_message(chat_id, text, parse_mode: "HTML")
    end

    {:ok, state}
  end

  @impl true
  def handle(_message, state) do
    {:ignored, state}
  end

  defp gen_and_cache_new_token(chat_id) do
    token = NotQwerty123.RandomPassword.gen_password(length: 24)
    token = String.upcase(token)

    true = Cachex.put!(:sponsorship, "#{token}", chat_id, ttl: @default_ttl)

    token
  end
end
