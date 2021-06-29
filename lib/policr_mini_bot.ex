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
  @spec id :: integer | nil
  def id, do: find_botinfo(:id)

  @doc """
  获取机器人的用户名。
  """
  @spec username :: String.t() | nil
  def username, do: find_botinfo(:username)

  @doc """
  获取机器人的名称。
  """
  @spec name :: String.t() | nil
  def name, do: find_botinfo(:name)

  @doc """
  获取机器人的头像文件 ID。
  """
  @spec photo_file_id :: String.t() | nil
  def photo_file_id, do: find_botinfo(:photo_file_id)

  @typep bot_field :: :id | :username | :name | :photo_file_id

  @spec find_botinfo(bot_field) :: any
  defp find_botinfo(field) do
    [{^field, value}] = :ets.lookup(:bot_info, field)

    value
  rescue
    _ -> nil
  end

  @official_bots ["policr_mini_bot", "policr_mini_test_bot"]
  def official_bots, do: @official_bots
end
