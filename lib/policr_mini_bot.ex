defmodule PolicrMiniBot do
  @moduledoc false

  alias :ets, as: ETS
  alias __MODULE__.BootHelper

  require Logger

  defmodule Info do
    @moduledoc false

    def from(bot_info: bot_info) when is_struct(bot_info, __MODULE__) do
      bot_info
    end

    use TypedStruct

    typedstruct do
      field :id, integer
      field :username, String.t()
      field :name, String.t()
      field :photo_file_id, String.t()
      field :is_third_party, boolean
    end
  end

  defmodule Chain do
    @moduledoc false

    defmacro __using__(opts) do
      quote do
        use Telegex.Chain, unquote(opts)
        use PolicrMini.I18n
        use PolicrMiniBot.MessageCaller

        import PolicrMiniBot.ChainContext
        import PolicrMiniBot.Helper
      end
    end
  end

  @doc """
  初始化机器人。

  包括获取机器人必要信息、缓存机器人数据、生成命令列表等操作。通常在机器人启动时调用。
  """
  @spec init :: Info.t()
  def init do
    if ETS.whereis(Info) == :undefined do
      # 获取机器人必要信息。
      Logger.info("Checking bot information...")
      %{username: username} = bot_info = BootHelper.fetch_bot_info()

      # 使用 Ets 缓存机器人数据。
      ETS.new(Info, [:set, :named_table])
      ETS.insert(Info, {:bot_info, bot_info})

      if config_get(:auto_gen_commands) do
        # 生成命令列表。
        BootHelper.gen_commands(username)
      end

      bot_info
    else
      Info.from(ETS.lookup(Info, :bot_info))
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

  @spec info :: Info.t() | nil
  def info() do
    case ETS.lookup(Info, :bot_info) do
      [{:bot_info, value}] ->
        value

      _ ->
        nil
    end
  end

  @official_bots ["policr_mini_bot", "policr_mini_test_bot"]

  def official_bots, do: @official_bots

  @type config_key ::
          :work_mode
          | :auto_gen_commands
          | :mosaic_method
          | :owner_id
          | :name
          | :unban_method
          | :opts

  @spec config_get(config_key, any) :: any
  def config_get(key, default \\ nil) do
    Application.get_env(:policr_mini, __MODULE__)[key] || default
  end
end
