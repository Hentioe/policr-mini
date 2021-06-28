defmodule PolicrMiniBot.RespSponsorshipCmdPlug do
  @moduledoc """
  /sponsorship 命令。
  """

  use PolicrMiniBot, plug: [commander: :sponsorship]

  @default_ttl 1000 * 60 * 10
  @five_min_mills 1000 * 60 * 5

  @impl true
  def handle(%{chat: %{type: "private"}} = message, state) do
    %{chat: %{id: chat_id}} = message
    key = "sponsorship-#{chat_id}"

    {token, ttl} =
      if token = Cachex.get!(:sponsorship, key) do
        ttl = Cachex.ttl!(:sponsorship, key) || 0

        if ttl < @five_min_mills do
          token = gen_and_cache_new_token(chat_id)

          {token, @default_ttl}
        else
          {token, ttl}
        end
      else
        token = gen_and_cache_new_token(chat_id)

        {token, @default_ttl}
      end

    min = Integer.floor_div(ttl, 60_000)

    web_root = PolicrMiniWeb.root_url(has_end_slash: true)

    text = """
    已生成一枚赞助令牌，使用它即可从 web 入口提交赞助表单。此令牌约在 #{min} 分钟后失效。

    <code>#{token}</code>

    点击<a href="#{web_root}?sponsorship=#{token}">此链接</a>可直接打开赞助表单，并自动填充此令牌。

    <i>提示：赞助令牌不会把您和表单中的赞助人关联上，但会保留创建信息。它是一种抵御攻击的措施，除此之外没有任何实际意义。</i>
    """

    {:ok, _} = Telegex.send_message(chat_id, text, parse_mode: "HTML")

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
