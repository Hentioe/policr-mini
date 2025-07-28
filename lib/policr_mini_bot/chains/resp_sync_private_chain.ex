defmodule PolicrMiniBot.RespSyncPrivateChain do
  @moduledoc """
  `/sync` 命令。

  此命令存在速度限制，15 秒内只能调用一次。
  """

  use PolicrMiniBot.Chain, {:command, :sync}

  alias PolicrMini.Schema.User
  alias PolicrMini.Accounts
  alias PolicrMiniBot.SpeedLimiter

  require Logger

  # 同步群组数据：群组信息、管理员列表。
  @impl true
  def handle(%{chat: %{type: "private"} = chat, from: from}, context) do
    speed_limit_key = "sync-#{chat.id}"
    waiting_secs = SpeedLimiter.get(speed_limit_key)
    user = Accounts.get_user(chat.id)

    cond do
      waiting_secs > 0 ->
        Telegex.send_message(chat.id, "同步过于频繁，请在 #{waiting_secs} 秒后重试。")

      true ->
        # 添加 30 秒的速度限制记录
        :ok = SpeedLimiter.put(speed_limit_key, 30)

        if sync_user(user, from) do
          Telegex.send_message(chat.id, "✅ 同步完成，已为您更新资料。")
        else
          Telegex.send_message(chat.id, "❌ 同步失败，请联系开发者。")
        end
    end

    {:stop, context}
  end

  @impl true
  def handle(_, context) do
    {:ok, context}
  end

  defp sync_user(nil, from) when is_struct(from, Telegex.Type.User) do
    params = %{
      id: from.id,
      token_ver: 0,
      first_name: from.first_name,
      last_name: from.last_name,
      username: from.username
    }

    with {:ok, user} <- Accounts.upsert_user(from.id, params),
         {:ok, user} <- sync_user_photo(user) do
      user
    else
      {:error, reason} ->
        Logger.error("Failed to sync user: #{inspect(reason: reason)}")
    end
  end

  defp sync_user(user, from) when is_struct(user, User) and is_struct(from, Telegex.Type.User) do
    params = %{
      first_name: from.first_name,
      last_name: from.last_name,
      username: from.username
    }

    with {:ok, user} <- Accounts.update_user(user, params),
         {:ok, user} <- sync_user_photo(user) do
      user
    else
      {:error, reason} ->
        # 同步已存在的用户失败
        Logger.error("Failed to sync existing user: #{inspect(reason: reason)}")
    end
  end
end
