defmodule PolicrMiniBot.LoginCommander do
  @moduledoc """
  登录命令。
  """

  use PolicrMiniBot, plug: [commander: :login]

  def handle(_message, state) do
    {:ok, state}
  end
end
