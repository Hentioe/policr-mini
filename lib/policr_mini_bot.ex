defmodule PolicrMiniBot do
  @moduledoc """
  机器人功能。
  """

  alias PolicrMiniBot.UpdatesPoller.BotInfo

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
  def id, do: find_bot_field(:id)

  @doc """
  获取机器人的用户名。
  """
  @spec username :: String.t() | nil
  def username, do: find_bot_field(:username)

  @doc """
  获取机器人的名称。
  """
  @spec name :: String.t() | nil
  def name, do: find_bot_field(:name)

  @doc """
  获取机器人的头像文件 ID。
  """
  @spec photo_file_id :: String.t() | nil
  def photo_file_id, do: find_bot_field(:photo_file_id)

  @typep bot_info_field :: :id | :username | :name | :photo_file_id

  @spec find_bot_field(bot_info_field) :: any
  defp find_bot_field(field) do
    if bot_info = info() do
      Map.get(bot_info, field)
    else
      nil
    end
  end

  @spec info :: BotInfo.t() | nil
  def info() do
    case :ets.lookup(BotInfo, :bot_info) do
      [{:bot_info, value}] ->
        value

      _ ->
        nil
    end
  end

  @official_bots ["policr_mini_bot", "policr_mini_test_bot"]
  def official_bots, do: @official_bots
end
