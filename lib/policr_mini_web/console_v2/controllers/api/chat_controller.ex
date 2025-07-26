defmodule PolicrMiniWeb.ConsoleV2.API.ChatController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.{Chats, Instances, Stats}
  alias PolicrMini.Chats.CustomKit
  alias PolicrMini.Chats.Verification

  action_fallback PolicrMiniWeb.ConsoleV2.API.FallbackController

  def index(%{assigns: %{user: user}} = conn, _params) do
    chats = Instances.find_user_chats(user.id)
    render(conn, "index.json", chats: chats)
  end

  @stats_schema %{
    range: [type: :string, in: ~w(today 7d 28d 90d), default: "7d"]
  }

  def stats(conn, %{"id" => chat_id} = params) do
    with {:ok, params} <- Tarams.cast(params, @stats_schema),
         {:ok, stats} <- Stats.query(range_to_opts(chat_id, params)) do
      render(conn, "stats.json", stats: stats)
    end
  end

  defp range_to_opts(chat_id, %{range: range}) do
    opts =
      case range do
        "today" ->
          [start: "-1d", every: "4h"]

        "7d" ->
          [start: "-7d", every: "1d"]

        "28d" ->
          [start: "-28d", every: "4d"]

        "90d" ->
          [start: "-90d", every: "30d"]
      end

    Keyword.put(opts, :chat_id, chat_id)
  end

  def scheme(conn, %{"id" => chat_id}) do
    scheme =
      if scheme = Chats.get_scheme_by_chat_id(chat_id) do
        scheme
      else
        Chats.upsert_scheme!(chat_id, %{})
      end

    render(conn, "scheme.json", scheme: scheme)
  end

  def customs(conn, _params) do
    # todo: 将示例数据改为实际查询
    customs = [
      %CustomKit{
        id: 1,
        chat_id: 1,
        title: "以下哪个城市不属于德国？",
        answers: ["+巴黎", "-柏林", "-慕尼黑", "-法兰克福"],
        attachment: "photo/xxx"
      },
      %CustomKit{
        id: 2,
        chat_id: 2,
        title: "哪个元素在元素周期表中是惰性气体？",
        answers: ["+氖", "-氧", "-氮", "-氢"]
      },
      %CustomKit{
        id: 3,
        chat_id: 3,
        title: "莎士比亚的四大悲剧不包括以下哪一部？",
        answers: ["+仲夏夜之梦", "-哈姆雷特", "-奥赛罗", "-李尔王"]
      },
      %CustomKit{
        id: 4,
        chat_id: 4,
        title: "以下哪项是计算机的中央处理器（CPU）的主要功能？",
        answers: ["+执行指令", "-存储数据", "-显示图像", "-打印文档"]
      },
      %CustomKit{
        id: 5,
        chat_id: 5,
        title: "光合作用的主要产物是什么？",
        answers: ["+葡萄糖和氧气", "-二氧化碳和水", "-氮气和氢气", "-淀粉和水"]
      }
    ]

    render(conn, "customs.json", customs: customs)
  end

  defp random_verification(index) do
    %Verification{
      id: index,
      target_user_id: index,
      seconds: Enum.random(30..120),
      status:
        Enum.random([
          :waiting,
          :passed,
          :timeout,
          :wronged,
          :expired,
          :manual_kick,
          :manual_ban
        ]),
      source: Enum.random([:joined, :join_request]),
      target_user_name: "用户#{index}",
      inserted_at: ~N[2023-10-01 12:00:00],
      updated_at: ~N[2023-10-01 12:00:00]
    }
  end

  def verifications(conn, _params) do
    verifications = Enum.map(1..15, &random_verification/1)

    render(conn, "verifications.json", verifications: verifications)
  end

  def operations(conn, _params) do
    operations =
      Enum.map(1..15, fn i ->
        %PolicrMini.Chats.Operation{
          id: i,
          action: Enum.random([:ban, :kick, :unban, :verify]),
          role: Enum.random([:system, :admin]),
          verification: random_verification(i),
          inserted_at: ~N[2023-10-01 12:00:00],
          updated_at: ~N[2023-10-01 12:00:00]
        }
      end)

    render(conn, "operations.json", operations: operations)
  end
end
