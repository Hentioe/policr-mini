defmodule PolicrMiniBot do
  @moduledoc """
  机器人功能。
  """

  defmacro __using__(plug: opts) do
    quote do
      import PolicrMiniBot.Helper

      alias PolicrMiniBot.{State, Cleaner}

      alias Telegex.Model.{
        Update,
        Message,
        CallbackQuery,
        InlineKeyboardMarkup,
        InlineKeyboardButton
      }

      use Telegex.Plug.Presets, unquote(opts)
    end
  end

  defmacro __using__(:plug) do
    quote do
      use Telegex.Plug
    end
  end

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
