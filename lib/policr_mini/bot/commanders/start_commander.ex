defmodule PolicrMini.Bot.StartCommander do
  @moduledoc """
  `/start` 命令的响应模块。
  与其它命令不同，`/start` 命令不需要完整匹配，以 `/start` 开头的**私聊文本消息**都能进入处理函数。
  这是因为 `/start` 是当前设计中唯一一个需要携带参数的命令。
  """
  use PolicrMini.Bot.Commander, :start

  alias PolicrMini.VerificationBusiness

  @doc """
  重写后的 `match?/1` 函数，以 `/start` 开始即匹配。
  """
  @impl true
  def match?(text), do: text |> String.starts_with?(@command)

  @doc """
  群组消息，忽略。
  """
  @impl true
  def handle(%{chat: %{type: "group"}}, state), do: {:ignored, state}

  @doc """
  群组（超级群）消息，忽略。
  """
  @impl true
  def handle(%{chat: %{type: "supergroup"}}, state), do: {:ignored, state}

  @doc """
  响应命令。
  如果命令没有携带参数，则发送包含链接的项目介绍。否则将参数整体传递给 `dispatch/1` 函数进一步拆分和分发。
  """
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

  @doc """
  分发命令参数。
  以 `_` 分割成更多参数，转发给 `handle_args/1` 函数处理。
  """
  def dispatch(arg, message), do: arg |> String.split("_") |> handle_args(message)

  @doc """
  处理 v1 版本的验证参数。
  """
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

  @doc """
  响应未知参数。
  """
  def handle_args(_, message) do
    %{chat: %{id: chat_id}} = message

    send_message(chat_id, "很抱歉，我未能理解您的意图。")
  end
end
