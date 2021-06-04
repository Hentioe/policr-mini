defmodule PolicrMiniBot.State do
  @moduledoc """
  在过滤器中传递的状态。
  """

  use TypedStruct

  typedstruct do
    field :action, atom
    field :takeovered, boolean()
    field :from_self, boolean()
    field :from_admin, boolean()
    field :deleted, boolean(), default: false
    field :done, boolean(), default: false
  end

  @doc """
  设置状态的动作字段。

  在一个状态中，动作只允许设置一次。如果出现多次设置，则表示某个插件出现了匹配错误。
  """
  def set_action(state, action) when is_struct(state, __MODULE__) do
    if state.action == nil do
      %{state | action: action}
    else
      raise "Repeat setting the action field, details: #{inspect(action: action, state: state)}"
    end
  end
end
