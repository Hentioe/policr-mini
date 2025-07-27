defmodule PolicrMiniWeb.ConsoleV2.API.ChatController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.{Chats, Instances, Stats}
  alias PolicrMini.Instances.Chat

  import Canary.Plugs

  plug :authorize_resource, model: Chat, except: [:index]

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
         {:ok, stats} <- Stats.query(stats_conds(chat_id, params)) do
      render(conn, "stats.json", stats: stats)
    end
  end

  defp stats_conds(chat_id, %{range: range}) do
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

  @verifications_schema %{
    offset: [type: :integer, default: 0],
    limit: [type: :integer, default: 120, number: [max: 120]],
    range: [type: :string, in: ~w(today 7d 30d), default: "7d"]
  }

  def verifications(conn, %{"id" => chat_id} = params) do
    with {:ok, params} <- Tarams.cast(params, @verifications_schema) do
      verifications = Chats.list_verifications(verifications_conds(chat_id, params))
      render(conn, "verifications.json", verifications: verifications)
    end
  end

  defp verifications_conds(chat_id, %{range: range} = params) do
    now = DateTime.utc_now()

    stop =
      case range do
        "today" ->
          DateTime.add(now, -1, :day)

        "7d" ->
          DateTime.add(now, -7, :day)

        "30d" ->
          DateTime.add(now, -30, :day)
      end

    [
      chat_id: chat_id,
      stop: stop,
      limit: params[:limit],
      offset: params[:offset]
    ]
  end

  @operations_schema %{
    offset: [type: :integer, default: 0],
    limit: [type: :integer, default: 120, number: [max: 120]],
    range: [type: :string, in: ~w(today 7d 30d), default: "7d"]
  }

  def operations(conn, %{"id" => chat_id} = params) do
    with {:ok, params} <- Tarams.cast(params, @operations_schema) do
      operations = Chats.list_operations(operations_conds(chat_id, params))
      render(conn, "operations.json", operations: operations)
    end
  end

  defp operations_conds(chat_id, %{range: range} = params) do
    now = DateTime.utc_now()

    stop =
      case range do
        "today" ->
          DateTime.add(now, -1, :day)

        "7d" ->
          DateTime.add(now, -7, :day)

        "30d" ->
          DateTime.add(now, -30, :day)
      end

    [
      chat_id: chat_id,
      stop: stop,
      limit: params[:limit],
      offset: params[:offset]
    ]
  end
end
