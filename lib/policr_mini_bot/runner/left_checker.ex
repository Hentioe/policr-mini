defmodule PolicrMiniBot.Runner.LeftChecker do
  @moduledoc false

  alias PolicrMini.Instances

  require Logger

  def run do
    Logger.info("Left check job has started")

    # 查找未接管且未离开状态的群
    chats = Instances.find_chats(taken_over: false, left_is_not: true)

    stream =
      chats
      # 检查自身状态并构建更新参数
      |> Stream.map(fn chat -> {chat, %{left: status(chat.id) == :left}} end)
      # 更新群组
      |> Stream.map(fn {chat, params} -> Instances.update_chat(chat, params) end)

    # 流计算，避免获取状态时长时间阻塞导致群数据在更新前过时
    _ = Enum.to_list(stream)

    Logger.info("Left check job has ended")
  end

  defp status(chat_id) do
    case Telegex.get_chat_member(chat_id, PolicrMiniBot.id()) do
      {:ok, _chat_memeber} ->
        # 存在，统一为成员状态
        :memeber

      # 超时，无返回，递归调用
      {:error, %Telegex.Model.RequestError{reason: :timeout}} ->
        :timer.sleep(500)

        status(chat_id)

      # 不存在
      {:error, _} ->
        :left
    end
  end
end
