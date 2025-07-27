defmodule PolicrMiniWeb.ConsoleV2.API.ChatController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.{Chats, Instances, Stats}
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

  def customs(conn, %{"id" => chat_id} = _params) do
    customs = Chats.find_custom_kits(chat_id)

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
