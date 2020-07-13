defmodule PolicrMiniBot do
  @moduledoc """
  机器人功能的根模块。
  """

  @doc """
  获取机器人的 ID。
  """
  @spec id :: integer()
  def id() do
    [{:id, id}] = :ets.lookup(:bot_info, :id)

    id
  end

  @doc """
  获取机器人的用户名。
  """
  @spec username :: String.t()
  def username() do
    [{:username, username}] = :ets.lookup(:bot_info, :username)

    username
  end
end
