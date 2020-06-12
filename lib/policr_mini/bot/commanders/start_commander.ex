defmodule PolicrMini.Bot.StartCommander do
  use PolicrMini.Bot.Commander, :start

  alias PolicrMini.VerificationBusiness

  @impl true
  def match?(text), do: text |> String.starts_with?(@command)

  @impl true
  def handle(%{chat: %{type: "group"}}, state), do: {:ignored, state}

  @impl true
  def handle(%{chat: %{type: "supergroup"}}, state), do: {:ignored, state}

  @impl true
  def handle(message, state) do
    %{chat: %{id: chat_id}, text: text} = message

    splited_text = text |> String.split(" ")

    if length(splited_text) == 2 do
      splited_text |> List.last() |> dispatch(message)
    else
      send_message(chat_id, "访问[这里](https://github.com/Hentioe/policr-mini)了解了解我吧～")
    end

    {:ok, state}
  end

  def dispatch(arg, message), do: arg |> String.split("_") |> handle_args(message)

  def handle_args(["verification", "v1", chat_id], message) do
    %{chat: %{id: from_user_id}} = message

    if _verification =
         VerificationBusiness.find_waiting_by_user(String.to_integer(chat_id), from_user_id) do
      # TODO: 计算剩余时间

      # TODO: 读取验证方案

      # TODO: 发送验证消息

      # TODO: 创建消息快照

      # TODO: 更新验证记录
      send_message(from_user_id, "正在对您进行验证。")
    else
      send_message(from_user_id, "您没有该目标群组的待验证记录。")
    end
  end

  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_message(chat_id, "很抱歉，我未能理解您的意图。")
  end
end
