defmodule PolicrMiniBot.ChainContext do
  @moduledoc false

  use Telegex.Chain.Context

  defcontext([
    {:chat_id, integer},
    {:user_id, integer},
    {:taken_over, boolean},
    {:action, atom},
    {:from_self, boolean},
    {:from_admin, boolean},
    {:deleted, boolean, default: false},
    {:done, boolean, default: false}
  ])

  @doc """
  设置上下文的动作字段。

  在一个上下文中，动作只允许设置一次。如果出现多次设置，则表示某个链出现了匹配错误。
  """
  def action(%{action: nil} = state, action) do
    %{state | action: action}
  end

  def action(state, action) do
    raise "Duplicated action field setting: #{inspect(action: action, state: state)}"
  end

  def done(state) do
    %{state | done: true}
  end
end
