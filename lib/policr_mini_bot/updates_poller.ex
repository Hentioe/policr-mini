defmodule PolicrMiniBot.UpdatesPoller do
  @moduledoc """
  轮询获取消息更新。
  """

  use GenServer

  alias PolicrMiniBot.Consumer
  alias PolicrMiniBot.Runner.ThirdPartiesMaintainer

  require Logger

  defmodule BotInfo do
    @moduledoc false

    defstruct [:id, :username, :name, :photo_file_id, :is_third_party]

    @type t :: %__MODULE__{
            id: integer,
            username: binary,
            name: binary,
            photo_file_id: binary,
            is_third_party: boolean
          }
    def from(bot_info: bot_info) when is_struct(bot_info, __MODULE__) do
      bot_info
    end
  end

  @doc """
  启动获取消息更新的轮询器。

  在启动之前会获取机器人自身信息并缓存，并设置初始为 `0` 的 `offset` 值。
  """
  def start_link(default \\ []) when is_list(default) do
    # 初始化 bot。
    bot_info =
      if :ets.whereis(BotInfo) == :undefined,
        do: init_bot(),
        else: BotInfo.from(:ets.lookup(BotInfo, :bot_info))

    Logger.info("Updates poller has started")

    GenServer.start_link(__MODULE__, %{offset: 0, is_third_party: bot_info.is_third_party},
      name: __MODULE__
    )
  end

  defp init_bot do
    # 获取机器人必要信息
    Logger.info("Checking bot information...")

    %{username: username} = bot_info = get_bot_info()

    Logger.info("Bot (@#{username}) is working")
    # 更新 Plug 中缓存的用户名。
    Telegex.Plug.update_username(username)
    # 缓存机器人数据。
    :ets.new(BotInfo, [:set, :named_table])
    :ets.insert(BotInfo, {:bot_info, bot_info})

    if Application.get_env(:policr_mini, PolicrMiniBot)[:auto_gen_commands] do
      {:ok, _} = username |> gen_commands() |> Telegex.set_my_commands()
    end

    bot_info
  end

  @impl true
  def init(state) do
    schedule_pull_updates()

    # 非第三方实例，添加第三方实例的维护任务
    if !state.is_third_party, do: ThirdPartiesMaintainer.add_job()

    {:ok, state}
  end

  # 注意：当前并未依赖对编辑消息、频道消息、内联查询等更新类型的接收才能实现的功能，如有需要需提前更新此列表。
  @allowed_updates [
    "message",
    "callback_query",
    "my_chat_member",
    "chat_member",
    "chat_join_request"
  ]

  @doc """
  处理异步消息。

  每收到一次 `:pull` 消息，就获取下一次更新，并修改状态中的 `offset` 值。
  """
  @impl true
  def handle_info(:pull, %{offset: last_offset} = state) do
    offset =
      case Telegex.get_updates(offset: last_offset, allowed_updates: @allowed_updates) do
        {:ok, updates} ->
          # 消费消息
          Enum.each(updates, &Consumer.receive/1)

          if Enum.empty?(updates) do
            last_offset
          else
            # 计算新的 offset
            List.last(updates).update_id + 1
          end

        {:error, %Telegex.Model.Error{description: "Bad Gateway"}} ->
          # Telegram 服务器故障，大幅度降低请求频率
          :timer.sleep(500)

          last_offset

        {:error, reason} ->
          Logger.warning("Pulling messages has failed: #{inspect(reason: reason)}")

          # 发生错误，降低请求频率
          :timer.sleep(200)

          last_offset
      end

    # 每 35ms 一个拉取请求，避免 429 错误
    :timer.sleep(35)
    schedule_pull_updates()
    {:noreply, %{state | offset: offset}}
  end

  #  如果收到 `{:ssl_closed, _}` 消息，会输出错误日志，目前没有做任何网络检查或试图挽救的措施。
  @impl true
  def handle_info({:ssl_closed, _} = msg, state) do
    Logger.error("SSL connection closed: #{inspect(msg: msg)}")

    {:noreply, state}
  end

  defp schedule_pull_updates do
    send(self(), :pull)
  end

  defp gen_commands(username) do
    alias Telegex.Model.BotCommand

    commands = [
      %BotCommand{
        command: "ping",
        description: "存活测试"
      },
      %BotCommand{
        command: "sync",
        description: "同步群数据"
      },
      %BotCommand{
        command: "login",
        description: "登入后台"
      }
    ]

    if username in PolicrMiniBot.official_bots() do
      commands ++
        [
          %BotCommand{
            command: "sponsorship",
            description: "赞助此项目（辅助提交赞助表单）"
          }
        ]
    else
      commands
    end
  end

  @spec get_avatar_file_id(integer) :: binary | nil
  defp get_avatar_file_id(user_id) do
    case Telegex.get_user_profile_photos(user_id) do
      {:ok, %{photos: [[%{file_id: file_id} | _]]}} ->
        file_id

      _ ->
        nil
    end
  end

  @doc """
  获取机器人信息。

  此函数在遇到部分网络问题时会自动重试，且没有次数上限。
  """
  # TODO: 将此函数迁移至 `PolicrMIniBot` 模块，并且和将基于 :ets 的缓存集成在其内部。
  @spec get_bot_info() :: BotInfo.t()
  def get_bot_info do
    case Telegex.get_me() do
      {:ok, %Telegex.Model.User{id: id, username: username, first_name: first_name}} ->
        %BotInfo{
          id: id,
          username: username,
          name: first_name,
          # TODO: 此处对头像的获取添加超时重试。
          photo_file_id: get_avatar_file_id(id),
          is_third_party: username not in PolicrMiniBot.official_bots()
        }

      {:error, %{reason: :timeout}} ->
        Logger.warning("Checking bot information timeout, retrying...")

      {:error, %{reason: :closed}} ->
        :timer.sleep(100)
        Logger.warning("Network error while checking bot information, retrying...")

        get_bot_info()

      {:error, e} ->
        raise e
    end
  end
end
