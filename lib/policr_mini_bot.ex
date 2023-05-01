defmodule PolicrMiniBot do
  @moduledoc """
  机器人功能。
  """

  alias PolicrMiniBot.UpdatesPoller.BotInfo

  defmacro __using__(plug: opts) do
    quote do
      import PolicrMiniBot.Helper
      import PolicrMiniBot.State

      # TODO: 将这些模块别名全部删除
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

  @type config_key :: :auto_gen_commands | :owner_id | :name | :unban_method | :opts

  @spec config(config_key, any) :: any
  def config(key, default \\ nil) do
    Application.get_env(:policr_mini, __MODULE__)[key] || default
  end

  @config_opts ["--independent"]

  @doc """
  检查可选项是否存在。

  ## 当前存在以下可选项：
    - `--independent`: 启用独立运营

  ## 例子
      iex> PolicrMiniBot.opt_exist?("--independent")
      false
  """
  @spec opt_exist?(String.t()) :: boolean
  def opt_exist?(opt_name) when opt_name in @config_opts do
    Enum.member?(config(:opts, []), opt_name)
  end
end
