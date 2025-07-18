defmodule PolicrMiniBot.BootHelper do
  @moduledoc false

  alias PolicrMiniBot.Info

  require Logger

  @spec fetch_bot_info :: Info.t()
  def fetch_bot_info do
    # 由于 Instance 缓存的需要，此处须使用 `Telegex.Instance.get_me/0` 不能使用 `Telegex.get_me/0`。
    case Telegex.Instance.fetch_me() do
      {:ok, %Telegex.Type.User{id: id, username: username, first_name: first_name}} ->
        %Info{
          id: id,
          username: username,
          name: first_name,
          # TODO: 此处对头像的获取添加超时重试。
          photo_file_id: get_avatar_file_id(id),
          is_third_party: username not in PolicrMiniBot.official_bots()
        }

      {:error, %{reason: :timeout}} ->
        Logger.warning("Checking bot information timeout, retrying...")
        :timer.sleep(100)

        fetch_bot_info()

      {:error, %{reason: :closed}} ->
        Logger.warning("Network error while checking bot information, retrying...")
        :timer.sleep(100)

        fetch_bot_info()

      {:error, e} ->
        raise e
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

  def gen_commands(username) do
    alias Telegex.Type.BotCommand

    commands = [
      %BotCommand{
        command: "embarrass_member",
        description: "验证此成员（实验性）"
      },
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
      },
      %BotCommand{
        command: "console",
        description: "进入控制台"
      }
    ]

    commands =
      if username in PolicrMiniBot.official_bots() do
        commands ++
          [
            %BotCommand{
              command: "sponsorship",
              description: "赞助此项目"
            }
          ]
      else
        commands
      end

    {:ok, _} = Telegex.set_my_commands(commands)
  end
end
